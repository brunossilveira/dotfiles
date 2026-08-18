#!/usr/bin/env bash
# The advisor. A pure function of recorded state: same state, same answer,
# whichever model asks. It reads and prints; it never acts, never calls GitHub,
# never spawns anything.
#
# Roles do not choose, skip, or reorder stages from prose, memory, or judgment.
# They run this, do exactly the action it names, record the outcome, run it
# again.
#
# Usage: swarm_next.sh [--all]      --all also lists work that could run concurrently

source "$(dirname "${BASH_SOURCE[0]}")/swarm_lib.sh"

show_all=false
[[ "${1:-}" == "--all" ]] && show_all=true

dir="$(require_run)"
run_id="$(kv_get "$dir/run" id)"
run_state="$(kv_get "$dir/run" state)"
S="$(dirname "${BASH_SOURCE[0]}")"

emit() {
    echo "RUN: $run_id"
    echo "NEXT_ACTION: $1"; shift
    while [[ $# -gt 0 ]]; do echo "$1"; shift; done
}

# --- terminal states --------------------------------------------------------

if [[ "$run_state" != "active" ]]; then
    emit none "REASON: run is $run_state" "DETAIL: $(kv_get "$dir/run" intent)"
    exit 0
fi

# --- blockers outrank everything -------------------------------------------

for b in $(open_blockers "$dir"); do
    emit handle_blocker \
        "BLOCKER: $b" \
        "KIND: $(kv_get "$dir/blockers/$b" kind)" \
        "TARGET: $(kv_get "$dir/blockers/$b" target)" \
        "REASON: $(kv_get "$dir/blockers/$b" detail)" \
        "COMMAND: swarm_blocker.sh resolve $b <detail>"
    exit 0
done

# --- a pending gate stops the run and waits on the operator ------------------

for g in $(open_gates "$dir"); do
    emit await_approval \
        "GATE: $g" \
        "KIND: $(kv_get "$dir/gates/$g" kind)" \
        "TARGET: $(kv_get "$dir/gates/$g" target)" \
        "QUESTION: $(kv_get "$dir/gates/$g" question)" \
        "REASON: waiting on the operator; an approval is real only once recorded" \
        "COMMAND_ON_APPROVAL: swarm_gate.sh approve $g <detail>" \
        "COMMAND_ON_REJECTION: swarm_gate.sh reject $g <reason>"
    exit 0
done

# --- shaping ----------------------------------------------------------------

# Stories are considered parents-first: a stack is walked from its base up, so
# the primary action is always the one furthest down the dependency chain.
story_depth() {
    local s="$1" depth=0 parent
    while true; do
        parent="$(story_field "$dir" "$s" depends_on)"
        [[ -z "$parent" ]] && break
        depth=$((depth + 1))
        s="$parent"
        (( depth > 20 )) && break   # cycle guard
    done
    echo "$depth"
}

dependency_order() {
    local s
    for s in $(story_ids "$dir" | sort); do
        echo "$(story_depth "$s") $s"
    done | sort -n -k1,1 -k2,2 | awk '{print $2}'
}

stories="$(dependency_order)"
plan_state="$(gate_state "$dir" plan)"
plan_rejections="$(kv_get "$dir/gates/plan" rejections || echo 0)"

if [[ -z "$stories" ]]; then
    if [[ "$plan_state" == "rejected" ]] && (( plan_rejections >= REWORK_LIMIT )); then
        emit open_blocker \
            "REASON: the plan was rejected $plan_rejections times; stop and talk instead of reshaping again" \
            "COMMAND: swarm_blocker.sh open plan-rejected plan run \"plan rejected $plan_rejections times\""
        exit 0
    fi
    emit run_analyst \
        "ROLE: analyst" \
        "REASON: the run has no stories yet" \
        "INTENT: $(kv_get "$dir/run" intent)" \
        "PROMPT: role-templates/analyst.prompt" \
        "RECORD_WITH: swarm_story.sh add <story-id> <title> [--depends-on <id>] [--risky]" \
        "THEN: swarm_gate.sh request plan plan run \"approve the story split and dependency order\""
    exit 0
fi

if [[ "$plan_state" != "approved" ]]; then
    if [[ "$plan_state" == "rejected" ]]; then
        emit run_analyst \
            "ROLE: analyst" \
            "REASON: plan rejected — reshape the stories ($plan_rejections of $REWORK_LIMIT)" \
            "DETAIL: $(kv_get "$dir/gates/plan" detail)"
    else
        emit request_plan_approval \
            "REASON: stories exist but the plan gate has not been requested" \
            "COMMAND: swarm_gate.sh request plan plan run \"approve the story split and dependency order\""
    fi
    exit 0
fi

# --- per-story pipeline -----------------------------------------------------
#
# Every story is scored independently. The primary action is the first one in
# story order; anything else actionable is concurrent work, because independent
# stories have disjoint write surfaces by construction.

story_action() {
    local s="$1"
    local parent risky pr pr_state ci base cur_base
    parent="$(story_field "$dir" "$s" depends_on)"
    risky="$(story_field "$dir" "$s" risky)"
    pr="$(story_field "$dir" "$s" pr)"
    pr_state="$(story_field "$dir" "$s" pr_state)"
    ci="$(story_field "$dir" "$s" ci)"

    # Merged stories are history.
    stage_done "$dir" "$s" merged && return 1

    if [[ "$pr_state" == "merged" ]]; then
        echo "record_merge|$s||the pull request is merged|swarm_story.sh record $s merged done"
        return 0
    fi

    # A stacked story cannot start before its parent has code to sit on.
    if [[ -n "$parent" ]] && ! stage_done "$dir" "$parent" implementation; then
        return 1
    fi

    # A parent that merged leaves its children sitting on a stale base.
    if [[ -n "$parent" ]] && stage_done "$dir" "$parent" merged; then
        cur_base="$(story_field "$dir" "$s" base)"
        base="$(kv_get "$dir/run" base)"
        if [[ -n "$cur_base" && "$cur_base" != "$base" ]]; then
            echo "restack|$s|merger|parent $parent merged; this branch is on $cur_base|swarm_worktree.sh restack $s"
            return 0
        fi
    fi

    [[ -z "$(story_field "$dir" "$s" worktree)" ]] && {
        echo "create_worktree|$s||the story has no branch yet|swarm_worktree.sh create $s"
        return 0
    }

    stage_done "$dir" "$s" implementation || {
        echo "run_implementer|$s|implementer|the story is approved and unimplemented|swarm_story.sh record $s implementation done <sha>"
        return 0
    }

    [[ -z "$pr" ]] && {
        echo "open_draft_pr|$s||implementation exists with no pull request|swarm_pr.sh open $s \"$(story_field "$dir" "$s" title)\""
        return 0
    }

    # Reviews. Rework loops back to the implementer, bounded.
    local code_v adv_v
    code_v="$(stage_verdict "$dir" "$s" code-review)"
    adv_v="$(stage_verdict "$dir" "$s" adversarial-review)"

    [[ -z "$code_v" ]] && {
        echo "run_code_reviewer|$s|code-reviewer|implementation has no review|swarm_story.sh record $s code-review <accepted|changes-requested> <sha>"
        return 0
    }
    [[ -z "$adv_v" ]] && {
        echo "run_adversarial_review|$s|codex|no independent pass on this branch yet|swarm_review.sh run $s"
        return 0
    }

    if [[ "$code_v" == "changes-requested" || "$adv_v" == "changes-requested" ]]; then
        local attempts; attempts="$(attempt_count "$dir" "$s" implementation)"
        if (( attempts >= REWORK_LIMIT )); then
            echo "open_blocker|$s||review requested changes $attempts times; stop instead of another attempt|swarm_blocker.sh open rework-$s rework $s \"$attempts rework cycles\""
        else
            echo "rework_implementer|$s|implementer|review requested changes (attempt $((attempts + 1)) of $REWORK_LIMIT)|swarm_story.sh assign $s implementation implementer $s-impl-$((attempts + 1))"
        fi
        return 0
    fi

    stage_done "$dir" "$s" cleanup || {
        echo "run_cleaner|$s|cleaner|review accepted; cleanup has not run|swarm_story.sh record $s cleanup done <sha>"
        return 0
    }

    if [[ "$risky" == "true" ]] && ! stage_done "$dir" "$s" hardening; then
        echo "run_hardener|$s|hardener|story marked risky and not hardened|swarm_story.sh record $s hardening done <sha>"
        return 0
    fi

    local arch_v; arch_v="$(stage_verdict "$dir" "$s" architecture)"
    [[ -z "$arch_v" ]] && {
        echo "run_architect|$s|architect|no architecture review yet|swarm_story.sh record $s architecture <accepted|changes-requested> <sha>"
        return 0
    }

    if [[ "$arch_v" == "changes-requested" ]] && ! stage_done "$dir" "$s" senior-implementation; then
        echo "run_senior_implementer|$s|senior-implementer|architecture review requested changes|swarm_story.sh record $s senior-implementation done <sha>"
        return 0
    fi

    [[ "$pr_state" == "draft" ]] && {
        echo "mark_pr_ready|$s||every stage cleared; the PR is still a draft|swarm_pr.sh ready $s"
        return 0
    }

    case "$ci" in
        failing)
            echo "run_implementer|$s|implementer|CI is failing on the pull request|swarm_story.sh record $s implementation done <sha>"
            return 0 ;;
        pending|"")
            echo "await_ci|$s||waiting on CI for the pull request|swarm_pr.sh sync $s"
            return 0 ;;
    esac

    # A stacked story merges after its parent, never before: its pull request
    # targets the parent's branch.
    if [[ -n "$parent" ]] && ! stage_done "$dir" "$parent" merged; then
        return 1
    fi

    echo "await_merge|$s||reviewed, clean, and green — the merge is the operator's|gh pr view $pr --web"
    return 0
}

primary=""
concurrent=()
for s in $stories; do
    if action="$(story_action "$s")"; then
        if [[ -z "$primary" ]]; then primary="$action"; else concurrent+=("$action"); fi
    fi
done

if [[ -z "$primary" ]]; then
    if [[ -n "$stories" ]] && ! echo "$stories" | while read -r s; do stage_done "$dir" "$s" merged || echo no; done | grep -q no; then
        emit complete_run \
            "REASON: every story merged" \
            "COMMAND: swarm_run.sh complete"
    else
        emit wait "REASON: every story is waiting on a dependency or on you"
    fi
    exit 0
fi

IFS='|' read -r action story role reason command <<< "$primary"
worktree="$(story_field "$dir" "$story" worktree)"
emit "$action" \
    "STORY: $story" \
    ${role:+"ROLE: $role"} \
    "REASON: $reason" \
    "COMMAND: $command" \
    ${role:+"PROMPT: role-templates/$role.prompt"} \
    ${worktree:+"WORKTREE: $worktree"}

if $show_all; then
    for c in "${concurrent[@]:-}"; do
        [[ -z "$c" ]] && continue
        IFS='|' read -r a s _ r _ <<< "$c"
        echo "CONCURRENT: $s $a — $r"
    done
fi
