#!/usr/bin/env bash
# Deterministic quality checks per stage, resolved for whatever languages the
# repository actually uses.
#
# A stage is not recorded until its check passes, and the threshold lives in a
# command rather than in an agent's opinion — a tool that exits non-zero cannot
# be talked around. Where no tool exists for a language, an agent judges against
# a written rubric instead, which is weaker but still recorded and still
# separate from the role that did the work.
#
# Usage:
#   swarm_check.sh detect [path]                    languages seen in the repo
#   swarm_check.sh plan <stage> [path]              what would run, or fallback
#   swarm_check.sh run <story-id> <stage>           run it, record pass or fail
#   swarm_check.sh record <story-id> <stage> <pass|fail> <detail...>
#   swarm_check.sh status <story-id> [stage]

source "$(dirname "${BASH_SOURCE[0]}")/swarm_lib.sh"

SKILL="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL_TABLE="$SKILL/reference/tool-table.conf"
CHECKED_STAGES="implementation cleanup hardening senior-implementation"

detect_languages() {
    local p="${1:-.}" langs=()
    if [[ -f "$p/Gemfile" ]] || compgen -G "$p/*.gemspec" >/dev/null 2>&1; then langs+=(ruby); fi
    if [[ -f "$p/package.json" ]]; then langs+=(javascript); fi
    if [[ -f "$p/pyproject.toml" || -f "$p/requirements.txt" || -f "$p/setup.py" ]]; then langs+=(python); fi
    if [[ -f "$p/go.mod" ]]; then langs+=(go); fi
    if [[ -f "$p/Cargo.toml" ]]; then langs+=(rust); fi
    if [[ -f "$p/mix.exs" ]]; then langs+=(elixir); fi
    if compgen -G "$p/*.sh" >/dev/null 2>&1 || compgen -G "$p/scripts/*.sh" >/dev/null 2>&1; then langs+=(shell); fi
    printf '%s\n' "${langs[@]:-}" | awk 'NF' | sort -u
}

# A repository always wins over the table: `check <stage> <command...>` and
# `skip <stage>` in .swarm.conf at its root.
repo_overrides() {
    local p="$1" stage="$2"
    [[ -f "$p/.swarm.conf" ]] || return 0
    sed -nE "s/^check[[:space:]]+${stage}[[:space:]]+//p" "$p/.swarm.conf"
}

repo_skips() {
    local p="$1" stage="$2"
    [[ -f "$p/.swarm.conf" ]] || return 1
    grep -qE "^skip[[:space:]]+${stage}([[:space:]]|$)" "$p/.swarm.conf"
}

# Entries defined for a language and stage, whether or not the tool is present.
defined_entries() {
    local p="$1" stage="$2" lang
    for lang in $(detect_languages "$p"); do
        awk -F'|' -v l="$lang" -v s="$stage" \
            'NF == 5 && $0 !~ /^[[:space:]]*#/ && $1 == l && $2 == s { print }' "$TOOL_TABLE"
    done
}

# Of those, the ones whose probe succeeds here.
runnable_commands() {
    local p="$1" stage="$2" line probe cmd
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        probe="$(cut -d'|' -f4 <<< "$line")"
        cmd="$(cut -d'|' -f5 <<< "$line")"
        if ( cd "$p" && eval "$probe" ) >/dev/null 2>&1; then echo "$cmd"; fi
    done < <(defined_entries "$p" "$stage")
}

# Defined for this language and stage, but not installed. These never degrade to
# an agent: a deterministic bar exists here, so the run says what is missing.
missing_tools() {
    local p="$1" stage="$2" line probe tool
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        tool="$(cut -d'|' -f3 <<< "$line")"
        probe="$(cut -d'|' -f4 <<< "$line")"
        if ! ( cd "$p" && eval "$probe" ) >/dev/null 2>&1; then
            echo "$tool ($(cut -d'|' -f1 <<< "$line"))"
        fi
    done < <(defined_entries "$p" "$stage")
}

# One of: override, tools, missing-tools, fallback — plus the detail lines that
# go with it. This is the whole precedence rule in one place.
resolve() {
    local p="$1" stage="$2"

    local overrides; overrides="$(repo_overrides "$p" "$stage" || true)"
    if [[ -n "$overrides" ]]; then
        echo "KIND: override"
        echo "$overrides" | sed 's/^/CMD: /'
        return 0
    fi

    local defined; defined="$(defined_entries "$p" "$stage" || true)"
    if [[ -z "$defined" ]]; then
        echo "KIND: fallback"
        local langs; langs="$(detect_languages "$p" | paste -sd, - || true)"
        echo "DETAIL: no check is defined for ${langs:-an unrecognised project} at stage $stage"
        return 0
    fi

    local missing; missing="$(missing_tools "$p" "$stage" || true)"
    if [[ -n "$missing" ]]; then
        echo "KIND: missing-tools"
        echo "$missing" | sed 's/^/TOOL: /'
        return 0
    fi

    echo "KIND: tools"
    runnable_commands "$p" "$stage" | sed 's/^/CMD: /'
}

cmd="${1:-}"; shift || true

case "$cmd" in
detect)
    detect_languages "${1:-$(pwd)}"
    ;;
plan)
    [[ $# -ge 1 ]] || die "Usage: swarm_check.sh plan <stage> [path]"
    stage="$1"; path="${2:-$(pwd)}"
    if repo_skips "$path" "$stage"; then
        echo "PLAN: skipped by .swarm.conf"
        exit 0
    fi
    resolved="$(resolve "$path" "$stage")"
    kind="$(sed -n 's/^KIND: //p' <<< "$resolved")"
    echo "PLAN: $kind"
    sed -n 's/^CMD: /COMMAND: /p;s/^TOOL: /MISSING_TOOL: /p;s/^DETAIL: /REASON: /p' <<< "$resolved"
    [[ "$kind" == "fallback" ]] && echo "RUBRIC: $SKILL/reference/check-rubrics/$stage.md"
    exit 0
    ;;
run)
    [[ $# -eq 2 ]] || die "Usage: swarm_check.sh run <story-id> <stage>"
    dir="$(require_run)"; story="$1"; stage="$2"
    path="$(story_field "$dir" "$story" worktree)"
    [[ -d "$path" ]] || die "No worktree for story: $story"
    f="$(story_dir "$dir" "$story")/checks/$stage"
    log="$(story_dir "$dir" "$story")/checks/$stage.log"
    mkdir -p "$(dirname "$f")"

    if repo_skips "$path" "$stage"; then
        kv_set "$f" result pass
        kv_set "$f" source skipped
        kv_set "$f" detail "skipped by .swarm.conf"
        kv_set "$f" at "$(now)"
        journal "$dir" "story $story: $stage check skipped by repo config"
        echo "RESULT: pass (skipped by .swarm.conf)"
        exit 0
    fi

    resolved="$(resolve "$path" "$stage")"
    kind="$(sed -n 's/^KIND: //p' <<< "$resolved")"

    case "$kind" in
    fallback)
        echo "RESULT: fallback"
        echo "REASON: $(sed -n 's/^DETAIL: //p' <<< "$resolved")"
        echo "RUBRIC: $SKILL/reference/check-rubrics/$stage.md"
        echo "RECORD_WITH: $(dirname "${BASH_SOURCE[0]}")/swarm_check.sh record $story $stage <pass|fail> <detail>"
        exit 0
        ;;
    missing-tools)
        kv_set "$f" result fail
        kv_set "$f" source missing-tools
        kv_set "$f" detail "$(sed -n 's/^TOOL: //p' <<< "$resolved" | paste -sd',' - | sed 's/,/, /g')"
        kv_set "$f" at "$(now)"
        journal "$dir" "story $story: $stage check blocked — missing $(kv_get "$f" detail)"
        echo "RESULT: missing-tools"
        sed -n 's/^TOOL: /MISSING_TOOL: /p' <<< "$resolved"
        echo "REASON: this language has a deterministic check for $stage, so an agent does not stand in for it"
        echo "FIX: install the tool, or set 'check $stage <command...>' or 'skip $stage' in .swarm.conf"
        exit 1
        ;;
    esac

    commands="$(sed -n 's/^CMD: //p' <<< "$resolved")"
    : > "$log"
    result=pass
    while IFS= read -r c; do
        [[ -z "$c" ]] && continue
        echo "\$ $c" >> "$log"
        if ( cd "$path" && eval "$c" ) >> "$log" 2>&1; then
            echo "PASS: $c"
        else
            echo "FAIL: $c"
            result=fail
            break          # later commands may depend on this one, as CRAP does on coverage
        fi
    done <<< "$commands"

    kv_set "$f" result "$result"
    kv_set "$f" source "$kind"
    kv_set "$f" commands "$(echo "$commands" | paste -sd';' -)"
    kv_set "$f" log "$log"
    kv_set "$f" at "$(now)"
    journal "$dir" "story $story: $stage check $result ($kind)"
    echo "RESULT: $result"
    echo "LOG: $log"
    [[ "$result" == "pass" ]]
    ;;
record)
    [[ $# -ge 3 ]] || die "Usage: swarm_check.sh record <story-id> <stage> <pass|fail> <detail...>"
    dir="$(require_run)"; story="$1" stage="$2" result="$3"; shift 3
    [[ "$result" == "pass" || "$result" == "fail" ]] || die "Result must be pass or fail."
    f="$(story_dir "$dir" "$story")/checks/$stage"
    mkdir -p "$(dirname "$f")"
    kv_set "$f" result "$result"
    kv_set "$f" source agent
    kv_set "$f" detail "$*"
    kv_set "$f" at "$(now)"
    journal "$dir" "story $story: $stage check $result (agent-judged) — $*"
    echo "RESULT: $result (agent-judged)"
    ;;
status)
    dir="$(require_run)"; story="$1"; shift || true
    if [[ $# -eq 1 ]]; then
        cat "$(story_dir "$dir" "$story")/checks/$1"
    else
        for s in $CHECKED_STAGES; do
            f="$(story_dir "$dir" "$story")/checks/$s"
            [[ -f "$f" ]] && echo "$s: $(kv_get "$f" result) ($(kv_get "$f" source))"
        done
    fi
    exit 0
    ;;
*)
    die "Usage: swarm_check.sh {detect|plan|run|record|status}"
    ;;
esac
