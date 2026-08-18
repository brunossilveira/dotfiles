#!/usr/bin/env bash
# Drive the advisor through a whole run with no agents and no network. Every
# tick prints the action the advisor named, then the simulator records the
# outcome that action would have produced and asks again.
#
# This is how the pipeline gets exercised for free, and how a change to
# swarm_next.sh gets checked against the sequence it is supposed to produce.
#
# Usage: swarm_sim.sh [--reviewer reject-once|accept] [--architect reject-once|accept]

set -Eeuo pipefail
S="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

reviewer_policy=accept
architect_policy=accept
while [[ $# -gt 0 ]]; do
    case "$1" in
        --reviewer) reviewer_policy="$2"; shift 2 ;;   # accept | reject-once | reject-always
        --architect) architect_policy="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

sandbox="$(mktemp -d)"
trap 'rm -r "$sandbox" 2>/dev/null || true' EXIT
export SWARM_STATE_HOME="$sandbox/state"

repo="$sandbox/repo"
mkdir -p "$repo"
git -C "$repo" init -q -b master
git -C "$repo" -c user.email=sim@example.com -c user.name=sim commit -q --allow-empty -m init
cd "$repo"

run() { "$S/$@"; }
field() { run swarm_next.sh | sed -n "s/^$1: //p" | head -1; }

echo "SIM_START reviewer=$reviewer_policy architect=$architect_policy"
echo

run swarm_run.sh start "add rate limiting to the API" >/dev/null

reviewed=0
tick=0
while (( tick < 40 )); do
    tick=$((tick + 1))
    plan="$(run swarm_next.sh --all)"
    action="$(sed -n 's/^NEXT_ACTION: //p' <<< "$plan" | head -1)"
    story="$(sed -n 's/^STORY: //p' <<< "$plan" | head -1)"

    # Do not sit idle while a merge or a CI run is pending: take the first
    # concurrent lane instead, exactly as the operator loop would.
    if [[ "$action" == "await_merge" || "$action" == "await_ci" ]]; then
        lane="$(sed -n 's/^CONCURRENT: //p' <<< "$plan" | head -1)"
        if [[ -n "$lane" ]]; then
            story="$(awk '{print $1}' <<< "$lane")"
            action="$(awk '{print $2}' <<< "$lane")"
        fi
    fi
    printf 'TICK %02d  %-24s %s\n' "$tick" "$action" "${story:-—}"

    case "$action" in
    run_analyst)
        run swarm_story.sh add limiter "token bucket limiter" >/dev/null
        run swarm_story.sh add endpoint "wire the limiter into the API" --depends-on limiter >/dev/null
        run swarm_gate.sh request plan plan run "approve the story split" >/dev/null
        ;;
    await_approval)
        gate="$(field GATE)"
        run swarm_gate.sh approve "$gate" approved-by-sim >/dev/null
        ;;
    request_plan_approval)
        run swarm_gate.sh request plan plan run "approve the story split" >/dev/null
        ;;
    create_worktree)
        run swarm_worktree.sh create "$story" >/dev/null
        ;;
    rework_implementer)
        run swarm_story.sh rework "$story" "review requested changes" >/dev/null
        ;;
    run_implementer)
        w="$(run swarm_worktree.sh path "$story")"
        git -C "$w" -c user.email=sim@example.com -c user.name=sim commit -q --allow-empty -m "implement $story"
        run swarm_story.sh assign "$story" implementation implementer "$story-impl-$tick" >/dev/null
        run swarm_story.sh record "$story" implementation done "$(git -C "$w" rev-parse --short=10 HEAD)" >/dev/null
        ;;
    open_draft_pr)
        run swarm_story.sh set "$story" pr "https://example.invalid/pr/$story" >/dev/null
        run swarm_story.sh set "$story" pr_state draft >/dev/null
        ;;
    run_code_reviewer)
        verdict=accepted
        if [[ "$reviewer_policy" == "reject-always" ]]; then
            verdict=changes-requested
        elif [[ "$reviewer_policy" == "reject-once" && $reviewed -eq 0 ]]; then
            verdict=changes-requested; reviewed=1
        fi
        run swarm_story.sh record "$story" code-review "$verdict" simsha >/dev/null
        ;;
    run_adversarial_review)
        run swarm_story.sh record "$story" adversarial-review accepted simsha >/dev/null
        ;;
    run_cleaner)     run swarm_story.sh record "$story" cleanup done simsha >/dev/null ;;
    run_hardener)    run swarm_story.sh record "$story" hardening done simsha >/dev/null ;;
    run_architect)
        verdict=accepted
        [[ "$architect_policy" == "reject-once" ]] && { verdict=changes-requested; architect_policy=accept; }
        run swarm_story.sh record "$story" architecture "$verdict" simsha >/dev/null
        ;;
    run_senior_implementer)
        run swarm_story.sh record "$story" senior-implementation done simsha >/dev/null ;;
    mark_pr_ready)
        run swarm_story.sh set "$story" pr_state open >/dev/null
        run swarm_story.sh set "$story" ci passing >/dev/null ;;
    await_ci)
        run swarm_story.sh set "$story" ci passing >/dev/null ;;
    await_merge)
        run swarm_story.sh set "$story" pr_state merged >/dev/null ;;
    record_merge)
        run swarm_story.sh record "$story" merged done >/dev/null ;;
    restack)
        run swarm_worktree.sh restack "$story" >/dev/null ;;
    complete_run)
        run swarm_run.sh complete >/dev/null
        echo
        echo "SIM_END complete after $tick ticks"
        exit 0 ;;
    open_blocker|handle_blocker)
        echo
        echo "SIM_END blocked: $(field REASON)"
        exit 0 ;;
    wait|none)
        echo
        echo "SIM_END $action: $(field REASON)"
        exit 0 ;;
    *)
        echo "SIM_ERROR unhandled action: $action" >&2
        exit 1 ;;
    esac
done

echo "SIM_ERROR did not converge in $tick ticks" >&2
exit 1
