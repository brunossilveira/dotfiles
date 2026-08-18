#!/usr/bin/env bash
# Rewrite the run summary. One screen: what the run is for, where each story
# stands, what is blocked, and what is waiting on the operator.
#
# The summary says where the run stands; journal.log beside it says how it got
# there.
#
# Usage: swarm_summary.sh [--print]

source "$(dirname "${BASH_SOURCE[0]}")/swarm_lib.sh"

dir="$(require_run)"
out="$dir/summary.md"
STAGES="implementation code-review adversarial-review cleanup hardening architecture senior-implementation merged"

dash() { local v="$1"; echo "${v:-—}"; }

stage_line() {
    local s="$1" stage out=""
    for stage in $STAGES; do
        stage_done "$dir" "$s" "$stage" || continue
        case "$(stage_verdict "$dir" "$s" "$stage")" in
            changes-requested) out+="$stage:changes-requested " ;;
            *) out+="$stage " ;;
        esac
    done
    echo "${out:-none}"
}

{
    echo "# $(kv_get "$dir/run" intent)"
    echo
    echo "Run \`$(kv_get "$dir/run" id)\` — $(kv_get "$dir/run" state), started $(kv_get "$dir/run" created_at)."
    echo "Repository \`$(kv_get "$dir/run" repo)\`, base \`$(kv_get "$dir/run" base)\`."
    echo
    echo "## Stories"
    echo
    if [[ -z "$(story_ids "$dir")" ]]; then
        echo "None yet — the analyst has not run."
    else
        echo "| Story | Depends on | Stages cleared | PR | CI |"
        echo "| --- | --- | --- | --- | --- |"
        for s in $(story_ids "$dir" | sort); do
            printf '| `%s` %s | %s | %s | %s | %s |\n' \
                "$s" "$(story_field "$dir" "$s" title)" \
                "$(dash "$(story_field "$dir" "$s" depends_on)")" \
                "$(stage_line "$s")" \
                "$(dash "$(story_field "$dir" "$s" pr)")" \
                "$(dash "$(story_field "$dir" "$s" ci)")"
        done
    fi
    echo
    echo "## Waiting on you"
    echo
    found=false
    for g in $(open_gates "$dir"); do
        found=true
        echo "- Gate \`$g\` ($(kv_get "$dir/gates/$g" kind)): $(kv_get "$dir/gates/$g" question)"
    done
    for s in $(story_ids "$dir" | sort); do
        [[ "$(story_field "$dir" "$s" pr_state)" == "open" ]] || continue
        stage_done "$dir" "$s" architecture || continue
        found=true
        echo "- Merge \`$s\`: $(story_field "$dir" "$s" pr)"
    done
    $found || echo "Nothing."
    echo
    echo "## Blocked"
    echo
    found=false
    for b in $(open_blockers "$dir"); do
        found=true
        echo "- \`$b\` ($(kv_get "$dir/blockers/$b" kind) on $(kv_get "$dir/blockers/$b" target)): $(kv_get "$dir/blockers/$b" detail)"
    done
    $found || echo "Nothing."
} > "$out"

[[ "${1:-}" == "--print" ]] && cat "$out"
echo "SUMMARY: $out"
