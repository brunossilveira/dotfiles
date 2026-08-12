#!/usr/bin/env bash
set -Eeuo pipefail

# Split the current hacktopus session and open Codex in the new pane with an
# adversarial review of this branch against its base branch.
#
# Usage: spawn-review.sh [--base BRANCH] [--title TITLE] [--focus TEXT]

BASE=""
TITLE="review"
FOCUS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --base)  BASE="$2"; shift 2 ;;
        --title) TITLE="$2"; shift 2 ;;
        --focus) FOCUS="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: $0 [--base BRANCH] [--title TITLE] [--focus TEXT]"
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "${HACKTOPUS_SESSION_ID:-}" ]]; then
    echo "Not inside a hacktopus session (\$HACKTOPUS_SESSION_ID is empty)." >&2
    echo "Run the review yourself: codex \"adversarial review of this branch vs its base\"" >&2
    exit 1
fi

git rev-parse --git-dir >/dev/null 2>&1 || { echo "Not a git repository." >&2; exit 1; }

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

PROMPT_FILE=$(mktemp -t adversarial-review)

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
    echo "Report findings ordered by severity. Do not edit any files."
} > "$PROMPT_FILE"

hacktopus session split \
    --title "$TITLE" \
    --command "codex \"\$(cat $PROMPT_FILE)\""

echo "Opened Codex in a split pane: $BRANCH vs $BASE"
