#!/usr/bin/env bash
# The adversarial pass: a different model, clean context, reading the story's
# branch against its base. Findings are captured to a file and posted to the
# pull request; the verdict is recorded in run state.
#
# Usage:
#   swarm_review.sh run <story-id> [--focus TEXT]   run Codex, wait, record
#   swarm_review.sh report <story-id>               print the last report path

source "$(dirname "${BASH_SOURCE[0]}")/swarm_lib.sh"

cmd="${1:-}"; shift || true
dir="$(require_run)"

case "$cmd" in
run)
    [[ $# -ge 1 ]] || die "Usage: swarm_review.sh run <story-id> [--focus TEXT]"
    story="$1"; shift
    focus=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --focus) focus="$2"; shift 2 ;;
            *) die "Unknown option: $1" ;;
        esac
    done
    command -v codex >/dev/null 2>&1 || die "codex is not installed."
    path="$(kv_get "$(story_dir "$dir" "$story")/story" worktree)"
    [[ -d "$path" ]] || die "No worktree for story: $story"
    branch="$(story_field "$dir" "$story" branch)"
    base="$(story_field "$dir" "$story" base)"
    title="$(story_field "$dir" "$story" title)"
    n=$(( $(ls "$dir/reviews" 2>/dev/null | grep -c "^${story}-" || true) + 1 ))
    report="$dir/reviews/${story}-${n}.md"
    prompt="$dir/reviews/${story}-${n}.prompt"

    {
        echo "Adversarial code review. Branch \`$branch\` against \`$base\`."
        echo
        echo "Read the change first:"
        echo "  git diff $base...HEAD"
        echo "  git log --oneline $base..HEAD"
        echo
        echo "The story this branch implements: $title"
        [[ -n "$focus" ]] && { echo; echo "Focus: $focus"; }
        echo
        echo "Your job is to find real defects, not to approve the work:"
        echo "- Correctness bugs, missed edge cases, nil/empty handling."
        echo "- Security issues, authorization gaps, injection, leaked secrets."
        echo "- Broken invariants, data/migration risk, backwards incompatibility."
        echo "- Behavior changes with no test, and tests that cannot fail."
        echo "- Scope beyond the story above."
        echo
        echo "Rules:"
        echo "- Assume the author is wrong. Verify each premise against the code as it"
        echo "  actually runs — read the callers, not just the diff."
        echo "- Every finding points at an exact file:line, says how it breaks, gives the fix."
        echo "- No praise. No style nits unless they change meaning."
        echo "- If nothing real is wrong, say so plainly instead of inventing findings."
        echo
        echo "Do not edit any files."
        echo "End your final message with a line reading exactly VERDICT: accepted"
        echo "or VERDICT: changes-requested. Findings above it, ordered by severity."
    } > "$prompt"

    journal "$dir" "story $story: adversarial review $n started"
    ( cd "$path" && codex exec --sandbox read-only -o "$report" "$(cat "$prompt")" ) \
        >"$report.log" 2>&1 || die "Codex failed; see $report.log"
    [[ -s "$report" ]] || die "Codex produced an empty report; see $report.log"

    if grep -qE '^VERDICT: accepted' "$report"; then
        verdict=accepted
    elif grep -qE '^VERDICT: changes-requested' "$report"; then
        verdict=changes-requested
    else
        die "Report has no VERDICT line: $report"
    fi

    "$(dirname "${BASH_SOURCE[0]}")/swarm_story.sh" record "$story" adversarial-review "$verdict" \
        "$(git -C "$path" rev-parse --short=10 HEAD)" "report $report" >/dev/null
    echo "VERDICT: $verdict"
    echo "REPORT_FILE: $report"
    ;;
report)
    [[ $# -eq 1 ]] || die "Usage: swarm_review.sh report <story-id>"
    ls -1 "$dir/reviews/$1-"*.md 2>/dev/null | tail -1 || die "No report for story: $1"
    ;;
*)
    die "Usage: swarm_review.sh {run|report}"
    ;;
esac
