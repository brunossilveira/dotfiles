#!/usr/bin/env bash
# Pull request facts. The advisor never calls GitHub itself — it reads what this
# script recorded, so its answer depends only on state and stays testable.
#
# Usage:
#   swarm_pr.sh open  <story-id> <title...>   open a draft PR for the story branch
#   swarm_pr.sh sync  <story-id>              refresh pr_state and ci from GitHub
#   swarm_pr.sh ready <story-id>              take the PR out of draft
#   swarm_pr.sh comment <story-id> <file>     post a review artifact as a PR comment

source "$(dirname "${BASH_SOURCE[0]}")/swarm_lib.sh"

cmd="${1:-}"; shift || true
dir="$(require_run)"
command -v gh >/dev/null 2>&1 || die "gh is not installed."

story_path() { kv_get "$(story_dir "$dir" "$1")/story" worktree; }

case "$cmd" in
open)
    [[ $# -ge 2 ]] || die "Usage: swarm_pr.sh open <story-id> <title...>"
    story="$1"; shift
    path="$(story_path "$story")"
    [[ -d "$path" ]] || die "No worktree for story: $story"
    branch="$(story_field "$dir" "$story" branch)"
    base="$(story_field "$dir" "$story" base)"
    git -C "$path" push -u origin "$branch" >/dev/null
    url="$(cd "$path" && gh pr create --draft --base "$base" --head "$branch" --title "$*" \
        --body "Story \`$story\` of swarm run \`$(kv_get "$dir/run" id)\`.

$(cat "$(story_dir "$dir" "$story")/story.md" 2>/dev/null || story_field "$dir" "$story" title)")"
    story_set "$dir" "$story" pr "$url"
    story_set "$dir" "$story" pr_state draft
    journal "$dir" "story $story: draft PR $url"
    echo "PR: $url"
    ;;
sync)
    [[ $# -eq 1 ]] || die "Usage: swarm_pr.sh sync <story-id>"
    story="$1"
    path="$(story_path "$story")"
    [[ -d "$path" ]] || die "No worktree for story: $story"
    json="$(cd "$path" && gh pr view --json state,isDraft,mergedAt,statusCheckRollup 2>/dev/null)" \
        || { echo "PR_STATE: none"; exit 0; }
    merged="$(echo "$json" | grep -o '"mergedAt":"[^"]*"' | head -1 || true)"
    draft="$(echo "$json" | grep -o '"isDraft":[a-z]*' | head -1 || true)"
    if [[ -n "$merged" ]]; then
        state=merged
    elif [[ "$draft" == '"isDraft":true' ]]; then
        state=draft
    else
        state=open
    fi
    if echo "$json" | grep -q '"conclusion":"FAILURE"'; then
        ci=failing
    elif echo "$json" | grep -q '"status":"IN_PROGRESS"\|"status":"QUEUED"'; then
        ci=pending
    elif echo "$json" | grep -q '"conclusion":"SUCCESS"'; then
        ci=passing
    else
        ci=none
    fi
    story_set "$dir" "$story" pr_state "$state"
    story_set "$dir" "$story" ci "$ci"
    echo "PR_STATE: $state"
    echo "CI: $ci"
    ;;
ready)
    [[ $# -eq 1 ]] || die "Usage: swarm_pr.sh ready <story-id>"
    path="$(story_path "$1")"
    ( cd "$path" && gh pr ready )
    story_set "$dir" "$1" pr_state open
    journal "$dir" "story $1: PR marked ready for review"
    echo "PR_STATE: open"
    ;;
comment)
    [[ $# -eq 2 ]] || die "Usage: swarm_pr.sh comment <story-id> <file>"
    [[ -f "$2" ]] || die "No such file: $2"
    path="$(story_path "$1")"
    ( cd "$path" && gh pr comment --body-file "$2" )
    journal "$dir" "story $1: posted $(basename "$2") to the PR"
    ;;
*)
    die "Usage: swarm_pr.sh {open|sync|ready|comment}"
    ;;
esac
