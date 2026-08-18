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

    state="$(cd "$path" && gh pr view --json state,isDraft,mergedAt -q \
        'if .mergedAt then "merged" elif .isDraft then "draft" else (.state | ascii_downcase) end' 2>/dev/null)" \
        || { echo "PR_STATE: none"; exit 0; }

    # Any failure wins, then anything still running, then success.
    ci="$(cd "$path" && gh pr view --json statusCheckRollup -q '
        [.statusCheckRollup[]? | (.conclusion // .state // .status // "") | ascii_downcase] as $c
        | if ($c | length) == 0 then "none"
          elif ($c | map(select(. == "failure" or . == "timed_out" or . == "cancelled" or . == "action_required")) | length) > 0 then "failing"
          elif ($c | map(select(. == "" or . == "pending" or . == "in_progress" or . == "queued" or . == "expected")) | length) > 0 then "pending"
          else "passing" end' 2>/dev/null)" || ci=none

    story_set "$dir" "$story" pr_state "$state"
    story_set "$dir" "$story" ci "${ci:-none}"
    echo "PR_STATE: $state"
    echo "CI: ${ci:-none}"
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
