#!/usr/bin/env bash
# Claude Code statusLine — powerline footer ported from the pi agent UI
# (.pi/agent/extensions/ui.ts). Reproduces the same Nerd Font glyphs,
# truecolor palette, and left/right segment groups.
#
# Receives session JSON on stdin. Requires a Nerd Font + truecolor terminal.

input=$(cat)

# --- Parse JSON (single jq pass) -------------------------------------------
# Use the unit separator (\x1f) — a non-whitespace IFS preserves empty fields,
# unlike tab/space which `read` collapses.
IFS=$'\037' read -r cwd branch_json in_tok out_tok cost model < <(
  echo "$input" | jq -r '
    [ (.cwd // .workspace.current_dir // ""),
      (.worktree.branch // .workspace.git_worktree // ""),
      (.context_window.total_input_tokens // 0),
      (.context_window.total_output_tokens // 0),
      (.cost.total_cost_usd // 0),
      (.model.id // .model.display_name // "")
    ] | map(tostring) | join("\u001f")'
)

dir=$(basename "${cwd:-$(pwd)}")

# Branch: prefer JSON, fall back to git
branch="$branch_json"
if [ -z "$branch" ] || [ "$branch" = "null" ]; then
  branch=$(git -C "${cwd:-.}" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
fi
[ "$branch" = "HEAD" ] && branch=""

# --- Powerline glyphs (Nerd Font) ------------------------------------------
PL_RIGHT=$''   # left-group end cap  ▶
PL_LEFT=$''    # right-group start cap ◀
I_BRANCH=$''   #
I_MODEL=$''    #
I_COST=$''     #
UP=$'↑'         # ↑
DOWN=$'↓'       # ↓
PI=$'π'         # π

# --- Palette (R;G;B) — matches ui.ts C{} -----------------------------------
BG1="50;50;65"
BG2="40;40;55"
ACCENT="100;180;240"
GREEN="120;190;120"
YELLOW="220;190;100"
MUTED="140;140;160"
BORDER="70;70;85"

ESC=$'\e'
RESET="${ESC}[0m"

# --- Number formatting (matches ui.ts fmt) ---------------------------------
fmt() {
  awk -v n="$1" 'BEGIN{
    if (n<1000) printf "%d", n;
    else if (n<10000) printf "%.1fk", n/1000;
    else if (n<1000000) printf "%.0fk", n/1000;
    else printf "%.1fM", n/1000000;
  }'
}

# --- Segment accumulators --------------------------------------------------
# Parallel arrays: text / fg / bg. Width is derived arithmetically (each
# segment renders as " text " plus exactly one powerline glyph = len+3).
L_TEXT=(); L_FG=(); L_BG=()
R_TEXT=(); R_FG=(); R_BG=()

add_left()  { L_TEXT+=("$1"); L_FG+=("$2"); L_BG+=("$3"); }
add_right() { R_TEXT+=("$1"); R_FG+=("$2"); R_BG+=("$3"); }

# --- Left group: project identity, branch ----------------------------------
add_left "${PI} ${dir}" "$ACCENT" "$BG1"
if [ -n "$branch" ]; then
  add_left "${I_BRANCH} ${branch}" "$GREEN" "$BG2"
fi

# --- Right group: tokens, cost, model --------------------------------------
if [ "${in_tok%.*}" -gt 0 ] 2>/dev/null || [ "${out_tok%.*}" -gt 0 ] 2>/dev/null; then
  add_right "${UP}$(fmt "${in_tok%.*}") ${DOWN}$(fmt "${out_tok%.*}")" "$MUTED" "$BG2"
fi
cost_nonzero=$(awk -v c="$cost" 'BEGIN{print (c>0)?1:0}')
if [ "$cost_nonzero" = "1" ]; then
  add_right "${I_COST}$(printf '%.3f' "$cost")" "$YELLOW" "$BG1"
fi
if [ -n "$model" ]; then
  mbg=$BG2; [ $(( ${#R_TEXT[@]} % 2 )) -eq 1 ] && mbg=$BG1
  add_right "${I_MODEL} ${model}" "$ACCENT" "$mbg"
fi

# --- Renderers (port of ui.ts renderPowerline) -----------------------------
render_left() {
  local out="" i n=${#L_TEXT[@]}
  for ((i=0; i<n; i++)); do
    local fg=${L_FG[i]} bg=${L_BG[i]} txt=${L_TEXT[i]}
    out+="${ESC}[38;2;${fg};48;2;${bg}m ${txt} ${RESET}"
    if (( i < n-1 )); then
      out+="${ESC}[38;2;${bg};48;2;${L_BG[i+1]}m${PL_RIGHT}${RESET}"
    else
      out+="${ESC}[38;2;${bg}m${PL_RIGHT}${RESET}"
    fi
  done
  printf '%s' "$out"
}

render_right() {
  local out="" i n=${#R_TEXT[@]}
  for ((i=0; i<n; i++)); do
    local fg=${R_FG[i]} bg=${R_BG[i]} txt=${R_TEXT[i]}
    if (( i == 0 )); then
      out+="${ESC}[38;2;${bg}m${PL_LEFT}${RESET}"
    else
      out+="${ESC}[38;2;${bg};48;2;${R_BG[i-1]}m${PL_LEFT}${RESET}"
    fi
    out+="${ESC}[38;2;${fg};48;2;${bg}m ${txt} ${RESET}"
  done
  printf '%s' "$out"
}

# Visible width: Σ(display chars of each text) + 3 per segment (2 pad + 1 glyph)
group_width() {
  local w=0 t
  for t in "$@"; do
    w=$(( w + $(printf '%s' "$t" | wc -m | tr -d ' ') + 3 ))
  done
  printf '%d' "$w"
}

left_str=$(render_left)
right_str=$(render_right)
left_w=$(group_width "${L_TEXT[@]}")
right_w=$(group_width "${R_TEXT[@]}")

# --- Width fill (Claude sets COLUMNS for v2.1.153+) ------------------------
cols=${COLUMNS:-0}
if [ "$cols" -gt 0 ]; then
  gap=$(( cols - left_w - right_w ))
  [ "$gap" -lt 1 ] && gap=1
  fill=$(printf '%*s' "$gap" '' | tr ' ' "$(printf '─')")
  printf '%s%s%s%s%s\n' "$left_str" "${ESC}[38;2;${BORDER}m" "$fill" "$RESET" "$right_str"
else
  printf '%s  %s\n' "$left_str" "$right_str"
fi
