#!/usr/bin/env python3
"""Stop hook: block finishing when code was edited but never verified.

Claude reads its session transcript. Codex records supported PostToolUse events
in the same session ledger because its transcript format is not a stable hook
interface. If edits are outstanding, returns a `block` decision carrying a nudge
that names the changed paths and the verification commands this workspace has.

Deliberately passive elsewhere: it never runs a command itself, never inspects
the working tree, and never claims a repo is green.

Adapted from hermes-agent's verification-evidence ledger + verify-on-stop nudge
(agent/verification_evidence.py, agent/verification_stop.py).

Config via env:
  CLAUDE_VERIFY_ON_STOP=off    disable entirely
  CLAUDE_VERIFY_ON_STOP=on     nudge only when the workspace has a detectable
                               verify command (default)
  CLAUDE_VERIFY_ON_STOP=adhoc  also nudge when none is detectable, asking for a
                               throwaway verification script instead
  AGENT_VERIFY_ON_STOP_STATE_DIR=/path  override state storage (mainly for tests)
"""

import fcntl
import hashlib
import json
import os
import re
import sys
import tempfile
from contextlib import contextmanager
from pathlib import Path

MAX_ATTEMPTS = 2
MAX_PATHS_IN_NUDGE = 8
MAX_COMMANDS_IN_NUDGE = 3
STATE_DIR = Path(os.environ.get(
    "AGENT_VERIFY_ON_STOP_STATE_DIR",
    Path.home() / ".claude" / "state" / "verify-on-stop",
))

EDIT_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}
PATH_KEYS = ("file_path", "notebook_path", "path")

# Edits to these carry no verifiable runtime behavior. A turn that touched only
# prose must never demand a test run.
NON_CODE_SUFFIXES = frozenset({
    ".md", ".markdown", ".mdx", ".rst", ".txt", ".text", ".adoc", ".asciidoc",
    ".org", ".log", ".csv", ".tsv", ".lock",
})
NON_CODE_NAMES = frozenset({
    "license", "licence", "notice", "authors", "contributors", "changelog",
    "codeowners",
})
# Throwaway workspaces. Edits here are scratch work, not deliverables.
SCRATCH_PREFIXES = ("/tmp/", "/private/tmp/", "/var/folders/")

HEREDOC_START_RE = re.compile(r"<<-?\s*[\"']?([A-Za-z_][A-Za-z0-9_]*)[\"']?")
PATCH_PATH_RE = re.compile(r"^\*\*\* (?:Add|Delete|Update) File: (.+)$", re.MULTILINE)

# A Bash command counts as verification evidence when it matches one of these.
VERIFY_COMMAND_RE = re.compile(
    r"""(?:^|[|&;]\s*|\s)(?:
        pytest | py\.test
      | (?:python3?\s+-m\s+)(?:pytest|unittest)
      | (?:bundle\s+exec\s+|be\s+)?(?:rspec|rubocop|rake\s+test)
      | (?:npm|pnpm|yarn|bun)\s+(?:run\s+)?(?:test|lint|typecheck|check)
      | (?:npx\s+)?(?:jest|vitest|eslint|tsc|biome)
      | go\s+(?:test|vet)
      | cargo\s+(?:test|clippy|check)
      | (?:ruff|mypy|pyright|shellcheck|luacheck|stylua|hadolint)
      | make\s+(?:test|tests|rspec|lint|rubocop|check|typecheck)
      | scripts/run_tests\.sh
    )\b""",
    re.VERBOSE,
)


def strip_heredocs(command):
    """Drop heredoc bodies so a quoted script mentioning `pytest` isn't evidence."""
    out = []
    lines = command.splitlines()
    index = 0
    while index < len(lines):
        line = lines[index]
        out.append(line)
        index += 1
        match = HEREDOC_START_RE.search(line)
        if not match:
            continue
        delimiter = match.group(1)
        while index < len(lines) and lines[index].strip() != delimiter:
            index += 1
        index += 1  # consume the terminator
    return "\n".join(out)


def is_non_code(raw):
    p = Path(raw)
    if p.suffix.lower() in NON_CODE_SUFFIXES:
        return True
    return not p.suffix and p.name.lower() in NON_CODE_NAMES


def is_scratch(raw, cwd=None):
    if cwd and not Path(raw).is_absolute():
        raw = str((Path(cwd) / raw).resolve())
    return raw.startswith(SCRATCH_PREFIXES)


def blocks(entry):
    message = entry.get("message")
    content = message.get("content") if isinstance(message, dict) else None
    return content if isinstance(content, list) else []


def result_failed(block):
    if block.get("is_error"):
        return True
    content = block.get("content")
    if isinstance(content, list):
        content = " ".join(
            c.get("text", "") for c in content if isinstance(c, dict)
        )
    return isinstance(content, str) and content.lstrip().startswith("Exit code ")


def codex_result_failed(response):
    if isinstance(response, dict):
        if (
            response.get("is_error")
            or response.get("isError")
            or response.get("status") in ("failed", "error")
        ):
            return True
        exit_code = response.get("exit_code")
        if isinstance(exit_code, int):
            return exit_code != 0
        response = response.get("output", response.get("content", ""))
    if isinstance(response, list):
        response = " ".join(
            item.get("text", "") for item in response if isinstance(item, dict)
        )
    return isinstance(response, str) and bool(re.search(
        r"(?:^Exit code [1-9]|Process exited with code [1-9]|^Script failed\b|"
        r"^Error\b|apply_patch verification failed)",
        response,
        re.IGNORECASE | re.MULTILINE,
    ))


def unverified_paths(transcript_path):
    """Code paths edited since the last passing verification command."""
    pending = []
    bash_commands = {}

    try:
        lines = Path(transcript_path).read_text(errors="replace").splitlines()
    except OSError:
        return []

    for line in lines:
        try:
            entry = json.loads(line)
        except ValueError:
            continue

        for block in blocks(entry):
            if not isinstance(block, dict):
                continue
            kind = block.get("type")

            if kind == "tool_use":
                args = block.get("input") or {}
                if block.get("name") in EDIT_TOOLS:
                    for key in PATH_KEYS:
                        raw = args.get(key)
                        if not isinstance(raw, str) or not raw:
                            continue
                        if is_non_code(raw) or is_scratch(raw):
                            continue
                        if raw not in pending:
                            pending.append(raw)
                        break
                elif block.get("name") == "Bash":
                    command = args.get("command")
                    if isinstance(command, str) and VERIFY_COMMAND_RE.search(
                        strip_heredocs(command)
                    ):
                        bash_commands[block.get("id")] = command

            elif kind == "tool_result":
                command = bash_commands.pop(block.get("tool_use_id"), None)
                if command and not result_failed(block):
                    pending = []

    return pending


def git_root(start):
    current = Path(start).resolve()
    for candidate in [current] + list(current.parents):
        if (candidate / ".git").exists():
            return candidate
    return current


def detect_verify_commands(root):
    """Verification commands this workspace actually offers, best first."""
    commands = []

    def add(command):
        if command not in commands:
            commands.append(command)

    makefile = root / "Makefile"
    if makefile.is_file():
        try:
            text = makefile.read_text(errors="replace")
        except OSError:
            text = ""
        for target in ("rspec", "tests", "test", "rubocop", "lint", "typecheck", "check"):
            if re.search(r"^%s:" % re.escape(target), text, re.MULTILINE):
                add("make %s" % target)

    package_json = root / "package.json"
    if package_json.is_file():
        try:
            scripts = (json.loads(package_json.read_text()) or {}).get("scripts") or {}
        except (OSError, ValueError):
            scripts = {}
        for name in ("test", "typecheck", "lint"):
            if name in scripts:
                add("npm test" if name == "test" else "npm run %s" % name)

    if (root / "scripts" / "run_tests.sh").is_file():
        add("scripts/run_tests.sh")
    if (root / ".rspec").is_file() or (root / "spec").is_dir():
        add("bundle exec rspec")
    if (root / ".rubocop.yml").is_file():
        add("bundle exec rubocop <changed paths>")
    if (root / "pyproject.toml").is_file() or (root / "pytest.ini").is_file():
        add("pytest")
    if (root / "go.mod").is_file():
        add("go test ./...")
    if (root / "Cargo.toml").is_file():
        add("cargo test")
    if (root / ".luacheckrc").is_file():
        add("luacheck <changed paths>")

    return commands


def state_file_for(session_id):
    return STATE_DIR / ("%s.json" % (session_id or "unknown"))


def read_state(session_id):
    try:
        return json.loads(state_file_for(session_id).read_text())
    except (OSError, ValueError):
        return {}


@contextmanager
def state_lock(session_id):
    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        lock_file = state_file_for(session_id).with_suffix(".lock").open("a")
    except OSError:
        yield
        return

    try:
        fcntl.flock(lock_file, fcntl.LOCK_EX)
        yield
    finally:
        fcntl.flock(lock_file, fcntl.LOCK_UN)
        lock_file.close()


def write_state(session_id, state):
    temp_path = None
    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile("w", dir=STATE_DIR, delete=False) as temp_file:
            json.dump(state, temp_file)
            temp_path = Path(temp_file.name)
        os.replace(temp_path, state_file_for(session_id))
    except OSError:
        if temp_path:
            try:
                temp_path.unlink(missing_ok=True)
            except OSError:
                pass


def claim_attempt(session_id, signature):
    with state_lock(session_id):
        state = read_state(session_id)
        # A different set of unverified paths is a different ask.
        attempts = 0 if state.get("signature") != signature else int(
            state.get("attempts", 0)
        )
        if attempts >= MAX_ATTEMPTS:
            return False
        state.update({"signature": signature, "attempts": attempts + 1})
        write_state(session_id, state)
    return True


def codex_pending_paths(session_id):
    state = read_state(session_id)
    return state.get("pending") if "pending" in state else None


def record_codex_event(payload):
    session_id = payload.get("session_id")
    tool_name = payload.get("tool_name")
    tool_input = payload.get("tool_input") or {}
    response = payload.get("tool_response")
    if codex_result_failed(response):
        return

    with state_lock(session_id):
        state = read_state(session_id)
        if tool_name == "apply_patch":
            command = tool_input.get("command", "")
            pending = state.get("pending", [])
            for raw in PATCH_PATH_RE.findall(command):
                if (
                    is_non_code(raw)
                    or is_scratch(raw, payload.get("cwd"))
                    or raw in pending
                ):
                    continue
                pending.append(raw)
            if pending:
                state["pending"] = pending
                write_state(session_id, state)
        elif tool_name == "Bash":
            command = tool_input.get("command", tool_input.get("cmd", ""))
            if isinstance(command, str) and VERIFY_COMMAND_RE.search(
                strip_heredocs(command)
            ):
                write_state(session_id, {"pending": []})


def format_paths(paths):
    shown = paths[:MAX_PATHS_IN_NUDGE]
    lines = ["- `%s`" % p for p in shown]
    remaining = len(paths) - len(shown)
    if remaining > 0:
        lines.append("- ... and %d more" % remaining)
    return "\n".join(lines)


def build_nudge(paths, commands, allow_adhoc):
    if commands:
        shown = ", ".join("`%s`" % c for c in commands[:MAX_COMMANDS_IN_NUDGE])
        suffix = ", ..." if len(commands) > MAX_COMMANDS_IN_NUDGE else ""
        instruction = (
            "Run the relevant verification command now (%s%s), read any failure, "
            "repair the code, and summarize what passed." % (shown, suffix)
        )
    elif allow_adhoc:
        instruction = (
            "No canonical test/lint/build command was detected for this workspace. "
            "Write a focused throwaway verification script under a tempfile path, "
            "run it against the changed behavior, clean it up, and report it "
            "explicitly as ad-hoc verification rather than a green suite."
        )
    else:
        return None

    return (
        "[System: You edited code in this session but no verification command has "
        "passed since those edits.\n\n"
        "Unverified paths:\n%s\n\n"
        "%s If verification is not possible, explain the concrete blocker instead "
        "of claiming the work is verified.]" % (format_paths(paths), instruction)
    )


def main():
    mode = (os.environ.get("CLAUDE_VERIFY_ON_STOP") or "on").strip().lower()
    if mode in ("0", "off", "false", "no"):
        return 0

    try:
        payload = json.load(sys.stdin)
    except ValueError:
        return 0

    if payload.get("hook_event_name") == "PostToolUse":
        record_codex_event(payload)
        return 0

    # Already continuing because of a stop hook — do not stack another block.
    if payload.get("stop_hook_active"):
        return 0

    paths = codex_pending_paths(payload.get("session_id"))
    if paths is None:
        transcript = payload.get("transcript_path")
        if not transcript:
            return 0
        paths = unverified_paths(transcript)
    if not paths:
        return 0

    signature = hashlib.sha256("\n".join(sorted(paths)).encode()).hexdigest()[:16]
    root = git_root(payload.get("cwd") or os.getcwd())
    nudge = build_nudge(paths, detect_verify_commands(root), allow_adhoc=(mode == "adhoc"))
    if not nudge:
        return 0

    if not claim_attempt(payload.get("session_id"), signature):
        return 0
    json.dump({"decision": "block", "reason": nudge}, sys.stdout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
