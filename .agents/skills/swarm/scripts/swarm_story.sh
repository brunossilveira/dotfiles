#!/usr/bin/env bash
# Stories and the stage facts recorded against them.
#
# Usage:
#   swarm_story.sh add <story-id> <title...> [--depends-on <id>] [--risky]
#   swarm_story.sh set <story-id> <key> <value...>
#   swarm_story.sh record <story-id> <stage> <verdict> [sha] [detail...]
#   swarm_story.sh assign <story-id> <stage> <role> <assignment-id>
#   swarm_story.sh status <story-id>
#   swarm_story.sh list
#
# Stages: implementation, code-review, adversarial-review, cleanup, hardening,
#         architecture, senior-implementation, merged
# Verdicts: accepted, changes-requested, done

source "$(dirname "${BASH_SOURCE[0]}")/swarm_lib.sh"

STAGES="implementation code-review adversarial-review cleanup hardening architecture senior-implementation merged"
VERDICTS="accepted changes-requested done"

valid_stage() { [[ " $STAGES " == *" $1 "* ]]; }
valid_verdict() { [[ " $VERDICTS " == *" $1 "* ]]; }

cmd="${1:-}"; shift || true
dir="$(require_run)"

case "$cmd" in
add)
    [[ $# -ge 2 ]] || die "Usage: swarm_story.sh add <story-id> <title...> [--depends-on <id>] [--risky]"
    id="$1"; shift
    depends=""; risky=false; title=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --depends-on) depends="$2"; shift 2 ;;
            --risky) risky=true; shift ;;
            *) title+=("$1"); shift ;;
        esac
    done
    [[ ${#title[@]} -gt 0 ]] || die "A story needs a title."
    sdir="$(story_dir "$dir" "$id")"
    [[ -e "$sdir" ]] && die "Story already exists: $id"
    mkdir -p "$sdir/stages" "$sdir/assignments"
    kv_set "$sdir/story" id "$id"
    kv_set "$sdir/story" title "${title[*]}"
    kv_set "$sdir/story" depends_on "$depends"
    kv_set "$sdir/story" risky "$risky"
    kv_set "$sdir/story" state pending
    kv_set "$sdir/story" created_at "$(now)"
    journal "$dir" "story added: $id (${title[*]})${depends:+ depends on $depends}"
    echo "STORY: $id"
    ;;
set)
    [[ $# -ge 3 ]] || die "Usage: swarm_story.sh set <story-id> <key> <value...>"
    id="$1" key="$2"; shift 2
    [[ -d "$(story_dir "$dir" "$id")" ]] || die "No such story: $id"
    story_set "$dir" "$id" "$key" "$*"
    journal "$dir" "story $id: $key = $*"
    ;;
record)
    [[ $# -ge 3 ]] || die "Usage: swarm_story.sh record <story-id> <stage> <verdict> [sha] [detail...]"
    id="$1" stage="$2" verdict="$3"; shift 3
    sha="${1:-}"; shift || true
    valid_stage "$stage" || die "Unknown stage: $stage (want one of: $STAGES)"
    valid_verdict "$verdict" || die "Unknown verdict: $verdict (want one of: $VERDICTS)"
    [[ -d "$(story_dir "$dir" "$id")" ]] || die "No such story: $id"
    f="$(stage_file "$dir" "$id" "$stage")"
    kv_set "$f" stage "$stage"
    kv_set "$f" verdict "$verdict"
    kv_set "$f" sha "$sha"
    kv_set "$f" detail "$*"
    kv_set "$f" at "$(now)"
    journal "$dir" "story $id: $stage $verdict${sha:+ at $sha}${*:+ — $*}"
    echo "RECORDED: $id $stage $verdict"
    ;;
assign)
    [[ $# -eq 4 ]] || die "Usage: swarm_story.sh assign <story-id> <stage> <role> <assignment-id>"
    id="$1" stage="$2" role="$3" aid="$4"
    valid_stage "$stage" || die "Unknown stage: $stage"
    f="$(story_dir "$dir" "$id")/assignments/$aid"
    kv_set "$f" id "$aid"
    kv_set "$f" story "$id"
    kv_set "$f" stage "$stage"
    kv_set "$f" role "$role"
    kv_set "$f" attempt "$(( $(attempt_count "$dir" "$id" "$stage") + 1 ))"
    kv_set "$f" state running
    kv_set "$f" started_at "$(now)"
    journal "$dir" "story $id: assigned $role for $stage ($aid)"
    echo "ASSIGNMENT: $aid"
    ;;
status)
    [[ $# -eq 1 ]] || die "Usage: swarm_story.sh status <story-id>"
    sdir="$(story_dir "$dir" "$1")"
    [[ -d "$sdir" ]] || die "No such story: $1"
    cat "$sdir/story"
    for stage in $STAGES; do
        f="$(stage_file "$dir" "$1" "$stage")"
        [[ -f "$f" ]] && echo "stage_${stage}: $(kv_get "$f" verdict)$(v=$(kv_get "$f" sha); [[ -n "$v" ]] && echo " @$v")"
    done
    exit 0
    ;;
list)
    for id in $(story_ids "$dir"); do
        echo "$id  $(story_field "$dir" "$id" state)  $(story_field "$dir" "$id" title)"
    done
    ;;
*)
    die "Usage: swarm_story.sh {add|set|record|assign|status|list}"
    ;;
esac
