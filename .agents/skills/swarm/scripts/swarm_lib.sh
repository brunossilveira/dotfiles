#!/usr/bin/env bash
# Shared helpers for the swarm scripts. Sourced, never run directly.
#
# State lives outside the repository so per-story worktrees all see the same
# run, nothing lands in a diff, and a worker cannot commit it by accident.

set -Eeuo pipefail

swarm_state_home() {
    echo "${SWARM_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/swarm}"
}

die() { echo "$*" >&2; exit 1; }

# --- key: value files -------------------------------------------------------

kv_get() {
    local file="$1" key="$2"
    [[ -f "$file" ]] || return 0
    sed -n "s/^${key}: \\(.*\\)$/\\1/p" "$file" | head -1
}

kv_set() {
    local file="$1" key="$2" value="$3" tmp
    mkdir -p "$(dirname "$file")"
    touch "$file"
    tmp="$file.tmp.$$"
    if grep -q "^${key}: " "$file" 2>/dev/null; then
        sed "s|^${key}: .*$|${key}: ${value}|" "$file" > "$tmp"
    else
        cat "$file" > "$tmp"
        echo "${key}: ${value}" >> "$tmp"
    fi
    mv "$tmp" "$file"
}

kv_has() {
    local file="$1" key="$2"
    [[ -n "$(kv_get "$file" "$key")" ]]
}

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]\{1,\}/-/g; s/^-//; s/-$//' | cut -c1-40
}

# --- repo and run resolution ------------------------------------------------

repo_root() {
    git rev-parse --show-toplevel 2>/dev/null || die "Not a git repository."
}

repo_slug() {
    slugify "$(basename "$(repo_root)")"
}

repo_state_dir() {
    echo "$(swarm_state_home)/$(repo_slug)"
}

# The active run is whichever run id sits in the repo's `current` pointer.
current_run_id() {
    local f; f="$(repo_state_dir)/current"
    [[ -f "$f" ]] && cat "$f" || true
}

run_dir() {
    local id="${1:-$(current_run_id)}"
    [[ -n "$id" ]] || die "No active run. Start one with: swarm_run.sh start <intent>"
    echo "$(repo_state_dir)/runs/$id"
}

require_run() {
    local dir; dir="$(run_dir "${1:-}")"
    [[ -d "$dir" ]] || die "Run directory missing: $dir"
    echo "$dir"
}

# --- journal ----------------------------------------------------------------
#
# Append-only, one line per decision or outcome. The summary says where the run
# stands; the journal says how it got there.

journal() {
    local dir="$1"; shift
    mkdir -p "$dir"
    echo "$(now) $*" >> "$dir/journal.log"
}

# --- stories ----------------------------------------------------------------

story_dir() {
    echo "$1/stories/$2"
}

story_ids() {
    local dir="$1"
    [[ -d "$dir/stories" ]] || return 0
    for d in "$dir"/stories/*/; do
        [[ -d "$d" ]] || continue
        basename "$d"
    done
}

story_field() {
    kv_get "$(story_dir "$1" "$2")/story" "$3"
}

story_set() {
    kv_set "$(story_dir "$1" "$2")/story" "$3" "$4"
}

# A stage is a recorded fact about a story: implemented at this sha, reviewed
# with this verdict. Absent file means the stage has not happened.
stage_file() {
    echo "$(story_dir "$1" "$2")/stages/$3"
}

stage_done() {
    [[ -f "$(stage_file "$1" "$2" "$3")" ]]
}

stage_verdict() {
    kv_get "$(stage_file "$1" "$2" "$3")" verdict
}

# Attempts are counted per story stage so rework can be bounded.
attempt_count() {
    local dir="$1" story="$2" stage="$3" n=0 f
    for f in "$(story_dir "$dir" "$story")"/assignments/*; do
        [[ -f "$f" ]] || continue
        [[ "$(kv_get "$f" stage)" == "$stage" ]] && n=$((n + 1))
    done
    echo "$n"
}

REWORK_LIMIT="${SWARM_REWORK_LIMIT:-2}"

check_field() {
    kv_get "$(story_dir "$1" "$2")/checks/$3" "$4"
}

# --- gates and blockers -----------------------------------------------------

open_gates() {
    local dir="$1" f
    for f in "$dir"/gates/*; do
        [[ -f "$f" ]] || continue
        [[ "$(kv_get "$f" state)" == "pending" ]] && basename "$f"
    done
    return 0
}

open_blockers() {
    local dir="$1" f
    for f in "$dir"/blockers/*; do
        [[ -f "$f" ]] || continue
        [[ "$(kv_get "$f" state)" == "open" ]] && basename "$f"
    done
    return 0
}

gate_state() {
    kv_get "$1/gates/$2" state
}
