#!/usr/bin/env -S jq -c -f

# Shared PreToolUse guard. Claude Code and Codex accept the same hook payload
# and the same structured deny decision, so .codex/hooks/deny-rm-rf.jq symlinks
# here. Matching is on the command text alone — Claude names its shell tool
# `Bash`, Codex names it something else, and nothing but a shell tool carries
# `tool_input.command`.

def RM_RF_PATTERN: "\\brm\\s+-[a-z]*r[a-z]*f[a-z]*\\s+|\\brm\\s+-[a-z]*f[a-z]*r[a-z]*\\s+";

def command: (.tool_input.command // .tool_input.cmd // "") | if type == "array" then join(" ") else . end;

if (command | test(RM_RF_PATTERN; "i"))
then {
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "Refusing to run `rm -rf`. Use `trash` or remove specific files instead."
  }
}
else empty end
