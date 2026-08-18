#!/usr/bin/env bash
# One branch and one worktree per story. The branch a story starts from is its
# dependency's branch when it has one, and the run's base otherwise — the stack
# is the dependency order made physical.
#
# Usage:
#   swarm_worktree.sh create <story-id>     create branch + worktree, print the path
#   swarm_worktree.sh path   <story-id>     print the worktree path
#   swarm_worktree.sh base   <story-id>     print the branch this story sits on
#   swarm_worktree.sh restack <story-id>    rebase onto the parent's new base
#   swarm_worktree.sh remove <story-id>     drop the worktree, keep the branch

source "$(dirname "${BASH_SOURCE[0]}")/swarm_lib.sh"

cmd="${1:-}"; shift || true
dir="$(require_run)"
repo="$(kv_get "$dir/run" repo)"
run_id="$(kv_get "$dir/run" id)"
run_base="$(kv_get "$dir/run" base)"

story_branch() { echo "swarm/$run_id/$1"; }
worktree_path() { echo "$dir/worktrees/$1"; }

base_branch_for() {
    local story="$1" parent
    parent="$(story_field "$dir" "$story" depends_on)"
    if [[ -n "$parent" ]]; then
        # A merged parent no longer needs to carry its children.
        if [[ "$(stage_verdict "$dir" "$parent" merged)" == "done" ]]; then
            echo "$run_base"
        else
            story_branch "$parent"
        fi
    else
        echo "$run_base"
    fi
}

case "$cmd" in
create)
    [[ $# -eq 1 ]] || die "Usage: swarm_worktree.sh create <story-id>"
    story="$1"
    [[ -d "$(story_dir "$dir" "$story")" ]] || die "No such story: $story"
    branch="$(story_branch "$story")"
    path="$(worktree_path "$story")"
    base="$(base_branch_for "$story")"
    if [[ -d "$path" ]]; then
        echo "WORKTREE: $path (existing)"
        exit 0
    fi
    git -C "$repo" rev-parse --verify --quiet "$base" >/dev/null \
        || die "Base branch does not exist: $base"
    git -C "$repo" worktree add -B "$branch" "$path" "$base" >/dev/null
    story_set "$dir" "$story" branch "$branch"
    story_set "$dir" "$story" base "$base"
    story_set "$dir" "$story" worktree "$path"
    story_set "$dir" "$story" state in-progress
    journal "$dir" "story $story: worktree $path on $branch (base $base)"
    echo "WORKTREE: $path"
    echo "BRANCH: $branch"
    echo "BASE: $base"
    ;;
path)
    worktree_path "$1"
    ;;
base)
    base_branch_for "$1"
    ;;
restack)
    [[ $# -eq 1 ]] || die "Usage: swarm_worktree.sh restack <story-id>"
    story="$1"
    path="$(worktree_path "$story")"
    [[ -d "$path" ]] || die "No worktree for story: $story"
    old="$(story_field "$dir" "$story" base)"
    new="$(base_branch_for "$story")"
    if [[ "$old" == "$new" ]]; then
        echo "RESTACK: not needed ($story already on $new)"
        exit 0
    fi
    if ! git -C "$path" rebase --onto "$new" "$old" 2>&1; then
        git -C "$path" rebase --abort 2>/dev/null || true
        journal "$dir" "story $story: restack onto $new conflicted"
        echo "RESTACK_CONFLICT: $story cannot move from $old to $new without help" >&2
        exit 1
    fi
    story_set "$dir" "$story" base "$new"
    journal "$dir" "story $story: restacked from $old onto $new"
    echo "RESTACK: $story now on $new"
    echo "PUSH_NEEDED: git -C $path push --force-with-lease"
    ;;
remove)
    [[ $# -eq 1 ]] || die "Usage: swarm_worktree.sh remove <story-id>"
    path="$(worktree_path "$1")"
    [[ -d "$path" ]] || { echo "WORKTREE: already gone"; exit 0; }
    git -C "$repo" worktree remove "$path" --force
    journal "$dir" "story $1: worktree removed"
    echo "WORKTREE: removed"
    ;;
*)
    die "Usage: swarm_worktree.sh {create|path|base|restack|remove}"
    ;;
esac
