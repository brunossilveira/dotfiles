#!/usr/bin/env bash
# Approval gates. An approval is real only once it is recorded here; a
# remembered "yes" did not happen.
#
# Usage:
#   swarm_gate.sh request <gate-id> <plan|review-disposition> <target> <question...>
#   swarm_gate.sh approve <gate-id> [detail...]
#   swarm_gate.sh reject  <gate-id> <reason...>
#   swarm_gate.sh status  [gate-id]

source "$(dirname "${BASH_SOURCE[0]}")/swarm_lib.sh"

KINDS="plan review-disposition"

cmd="${1:-}"; shift || true
dir="$(require_run)"

case "$cmd" in
request)
    [[ $# -ge 4 ]] || die "Usage: swarm_gate.sh request <gate-id> <kind> <target> <question...>"
    id="$1" kind="$2" target="$3"; shift 3
    [[ " $KINDS " == *" $kind "* ]] || die "Unknown gate kind: $kind (want one of: $KINDS)"
    f="$dir/gates/$id"
    [[ -f "$f" && "$(kv_get "$f" state)" == "pending" ]] && die "Gate already pending: $id"
    kv_set "$f" id "$id"
    kv_set "$f" kind "$kind"
    kv_set "$f" target "$target"
    kv_set "$f" question "$*"
    kv_set "$f" state pending
    kv_set "$f" rejections "$(kv_get "$f" rejections || echo 0)"
    kv_set "$f" requested_at "$(now)"
    journal "$dir" "gate $id requested ($kind on $target): $*"
    echo "GATE: $id pending"
    ;;
approve)
    [[ $# -ge 1 ]] || die "Usage: swarm_gate.sh approve <gate-id> [detail...]"
    id="$1"; shift
    f="$dir/gates/$id"
    [[ -f "$f" ]] || die "No such gate: $id"
    kv_set "$f" state approved
    kv_set "$f" detail "${*:-approved-by-operator}"
    kv_set "$f" decided_at "$(now)"
    journal "$dir" "gate $id approved: ${*:-approved-by-operator}"
    echo "GATE: $id approved"
    ;;
reject)
    [[ $# -ge 2 ]] || die "Usage: swarm_gate.sh reject <gate-id> <reason...>"
    id="$1"; shift
    f="$dir/gates/$id"
    [[ -f "$f" ]] || die "No such gate: $id"
    n=$(( $(kv_get "$f" rejections || echo 0) + 1 ))
    kv_set "$f" state rejected
    kv_set "$f" rejections "$n"
    kv_set "$f" detail "$*"
    kv_set "$f" decided_at "$(now)"
    journal "$dir" "gate $id rejected ($n): $*"
    echo "GATE: $id rejected (rejection $n of $REWORK_LIMIT)"
    if (( n >= REWORK_LIMIT )); then
        echo "LIMIT_REACHED: rework bound hit; the advisor will raise a blocker instead of retrying"
    fi
    ;;
status)
    if [[ $# -eq 1 ]]; then
        cat "$dir/gates/$1"
    else
        for f in "$dir"/gates/*; do
            [[ -f "$f" ]] || continue
            echo "$(basename "$f")  $(kv_get "$f" state)  $(kv_get "$f" kind)  $(kv_get "$f" target)"
        done
    fi
    ;;
*)
    die "Usage: swarm_gate.sh {request|approve|reject|status}"
    ;;
esac
