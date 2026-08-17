#!/usr/bin/env bash
set -Eeuo pipefail

# Run an adversarial Codex review of this branch against its base branch, and
# write the findings to a file the calling agent can read — no copy-pasting.
#
# By default it splits the current hacktopus session so the review is visible in
# a pane beside you; outside a hacktopus session (or with --headless) it runs in
# the background instead. Either way the findings land in the same report file.
#
# Usage: spawn-review.sh [--base BRANCH] [--title TITLE] [--focus TEXT]
#                        [--out FILE] [--headless]
#
# Prints REPORT_FILE=<path> and DONE_FILE=<path>. The review is finished when
# DONE_FILE exists; its contents are the codex exit code.

BASE=""
TITLE="review"
FOCUS=""
REPORT=""
HEADLESS=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --base)  BASE="$2"; shift 2 ;;
        --title) TITLE="$2"; shift 2 ;;
        --focus) FOCUS="$2"; shift 2 ;;
        --out)   REPORT="$2"; shift 2 ;;
        --headless) HEADLESS=1; shift ;;
        --help|-h)
            echo "Usage: $0 [--base BRANCH] [--title TITLE] [--focus TEXT] [--out FILE] [--headless]"
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

git rev-parse --git-dir >/dev/null 2>&1 || { echo "Not a git repository." >&2; exit 1; }
command -v codex >/dev/null 2>&1 || { echo "codex is not installed." >&2; exit 1; }

if [[ -z "$BASE" ]]; then
    if BASE=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null); then
        BASE="${BASE#origin/}"
    elif git show-ref --verify --quiet refs/heads/main; then
        BASE="main"
    elif git show-ref --verify --quiet refs/heads/master; then
        BASE="master"
    else
        echo "Could not determine the base branch. Pass --base BRANCH." >&2
        exit 1
    fi
fi

BRANCH=$(git branch --show-current)
if [[ "$BRANCH" == "$BASE" ]]; then
    echo "Current branch is the base branch ($BASE); there is nothing to review." >&2
    exit 1
fi

if [[ -z "${HACKTOPUS_SESSION_ID:-}" ]]; then
    HEADLESS=1
fi

REVIEW_DIR="${TMPDIR:-/tmp}/adversarial-review"
mkdir -p "$REVIEW_DIR"
if [[ -z "$REPORT" ]]; then
    REPORT="$REVIEW_DIR/$(echo "$BRANCH" | tr '/' '-')-$$.md"
fi
DONE_FILE="$REPORT.done"
LOG_FILE="$REPORT.log"
rm -f "$REPORT" "$DONE_FILE" "$LOG_FILE"

PROMPT_FILE="$REVIEW_DIR/prompt-$$.txt"

{
    echo "Adversarial code review. Branch \`$BRANCH\` against \`$BASE\`."
    echo
    echo "Read the change first:"
    echo "  git diff $BASE...HEAD"
    echo "  git log --oneline $BASE..HEAD"
    echo "  git status   # uncommitted work counts too"
    echo
    echo "Your job is to find real defects, not to approve the work:"
    echo "- Correctness bugs, missed edge cases, off-by-one, nil/empty handling."
    echo "- Security issues, authorization gaps, injection, leaked secrets."
    echo "- Broken invariants, data/migration risk, backwards incompatibility."
    echo "- Behavior changes with no test, and tests that cannot fail."
    echo
    echo "Rules:"
    echo "- Assume the author is wrong. Verify each premise against the code as it"
    echo "  actually runs — read the surrounding files and the callers, not just the diff."
    echo "- Every finding points at an exact file:line, says how it breaks, and gives the fix."
    echo "- No praise. No style nits unless they change meaning."
    echo "- If nothing real is wrong, say that plainly instead of inventing findings."
    echo
    if [[ -n "$FOCUS" ]]; then
        echo "What the change is meant to do: $FOCUS"
        echo
    fi
    echo "Do not edit any files."
    echo "Your final message IS the report: markdown, findings ordered by severity,"
    echo "one section per finding with file:line, how it breaks, and the fix."
} > "$PROMPT_FILE"

RUN="codex exec --sandbox read-only -o '$REPORT' \"\$(cat '$PROMPT_FILE')\"; echo \$? > '$DONE_FILE'"

if [[ "$HEADLESS" -eq 1 ]]; then
    nohup bash -c "$RUN" >"$LOG_FILE" 2>&1 &
    echo "Codex review running in the background: $BRANCH vs $BASE"
else
    hacktopus session split \
        --title "$TITLE" \
        --command "$RUN; echo; echo 'Report: $REPORT'; echo 'Follow up with: codex resume --last'; exec \$SHELL" \
        >"$LOG_FILE" 2>&1 \
        || { echo "hacktopus split failed (see $LOG_FILE); falling back to headless." >&2
             nohup bash -c "$RUN" >>"$LOG_FILE" 2>&1 & }
    echo "Opened Codex in a split pane: $BRANCH vs $BASE"
fi

echo "REPORT_FILE=$REPORT"
echo "DONE_FILE=$DONE_FILE"
