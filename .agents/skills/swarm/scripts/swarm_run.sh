#!/usr/bin/env bash
# Start, inspect, and end runs.
#
# Usage:
#   swarm_run.sh start <intent...>        create a run and its plan gate
#   swarm_run.sh show [run-id]            print the run record
#   swarm_run.sh path [run-id]            print the state directory
#   swarm_run.sh list                     runs known for this repository
#   swarm_run.sh use <run-id>             make an existing run current
#   swarm_run.sh complete [detail...]     mark the run complete
#   swarm_run.sh abandon <reason...>      stop the run, keep the record

source "$(dirname "${BASH_SOURCE[0]}")/swarm_lib.sh"

cmd="${1:-}"; shift || true

case "$cmd" in
start)
    [[ $# -gt 0 ]] || die "Usage: swarm_run.sh start <intent...>"
    intent="$*"
    root="$(repo_root)"
    id="$(date -u +%Y%m%d)-$(slugify "$intent")"
    dir="$(repo_state_dir)/runs/$id"
    [[ -e "$dir" ]] && die "Run already exists: $id"
    mkdir -p "$dir"/{stories,gates,blockers,reviews,worktrees}
    kv_set "$dir/run" id "$id"
    kv_set "$dir/run" intent "$intent"
    kv_set "$dir/run" repo "$root"
    kv_set "$dir/run" base "$(git -C "$root" symbolic-ref --quiet --short HEAD || echo master)"
    kv_set "$dir/run" state active
    kv_set "$dir/run" created_at "$(now)"
    mkdir -p "$(repo_state_dir)"
    echo "$id" > "$(repo_state_dir)/current"
    journal "$dir" "run started: $intent"
    echo "RUN: $id"
    echo "DIR: $dir"
    ;;
show)
    dir="$(require_run "${1:-}")"
    cat "$dir/run"
    ;;
path)
    require_run "${1:-}"
    ;;
list)
    d="$(repo_state_dir)/runs"
    [[ -d "$d" ]] || exit 0
    current="$(current_run_id)"
    for r in "$d"/*/; do
        [[ -d "$r" ]] || continue
        id="$(basename "$r")"
        marker=" "; [[ "$id" == "$current" ]] && marker="*"
        echo "$marker $id  $(kv_get "$r/run" state)  $(kv_get "$r/run" intent)"
    done
    ;;
use)
    [[ $# -eq 1 ]] || die "Usage: swarm_run.sh use <run-id>"
    [[ -d "$(repo_state_dir)/runs/$1" ]] || die "No such run: $1"
    echo "$1" > "$(repo_state_dir)/current"
    echo "RUN: $1"
    ;;
complete)
    dir="$(require_run)"
    kv_set "$dir/run" state complete
    kv_set "$dir/run" ended_at "$(now)"
    journal "$dir" "run complete: ${*:-all stories merged}"
    echo "RUN_STATE: complete"
    ;;
abandon)
    [[ $# -gt 0 ]] || die "Usage: swarm_run.sh abandon <reason...>"
    dir="$(require_run)"
    kv_set "$dir/run" state abandoned
    kv_set "$dir/run" ended_at "$(now)"
    journal "$dir" "run abandoned: $*"
    echo "RUN_STATE: abandoned"
    ;;
*)
    die "Usage: swarm_run.sh {start|show|path|list|use|complete|abandon}"
    ;;
esac
