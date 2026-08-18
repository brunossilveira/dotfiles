#!/usr/bin/env bash
# Durable blockers. A run with an open blocker is stopped, and says so.
#
# Usage:
#   swarm_blocker.sh open <blocker-id> <kind> <target> <detail...>
#   swarm_blocker.sh resolve <blocker-id> <detail...>
#   swarm_blocker.sh list

source "$(dirname "${BASH_SOURCE[0]}")/swarm_lib.sh"

cmd="${1:-}"; shift || true
dir="$(require_run)"

case "$cmd" in
open)
    [[ $# -ge 4 ]] || die "Usage: swarm_blocker.sh open <blocker-id> <kind> <target> <detail...>"
    id="$1" kind="$2" target="$3"; shift 3
    f="$dir/blockers/$id"
    kv_set "$f" id "$id"
    kv_set "$f" kind "$kind"
    kv_set "$f" target "$target"
    kv_set "$f" detail "$*"
    kv_set "$f" state open
    kv_set "$f" opened_at "$(now)"
    journal "$dir" "blocker $id opened ($kind on $target): $*"
    echo "BLOCKER: $id open"
    ;;
resolve)
    [[ $# -ge 2 ]] || die "Usage: swarm_blocker.sh resolve <blocker-id> <detail...>"
    id="$1"; shift
    f="$dir/blockers/$id"
    [[ -f "$f" ]] || die "No such blocker: $id"
    kv_set "$f" state resolved
    kv_set "$f" resolution "$*"
    kv_set "$f" resolved_at "$(now)"
    journal "$dir" "blocker $id resolved: $*"
    echo "BLOCKER: $id resolved"
    ;;
list)
    for f in "$dir"/blockers/*; do
        [[ -f "$f" ]] || continue
        echo "$(basename "$f")  $(kv_get "$f" state)  $(kv_get "$f" kind)  $(kv_get "$f" target)  $(kv_get "$f" detail)"
    done
    ;;
*)
    die "Usage: swarm_blocker.sh {open|resolve|list}"
    ;;
esac
