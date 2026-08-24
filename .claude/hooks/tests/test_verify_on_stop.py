import json
import os
import subprocess
import sys
import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path


HOOK = Path(__file__).parents[1] / "verify-on-stop.py"


class VerifyOnStopHookTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory(dir=HOOK.parents[2])
        self.addCleanup(self.temp_dir.cleanup)
        self.root = Path(self.temp_dir.name)
        (self.root / ".git").mkdir()
        (self.root / "pyproject.toml").touch()
        self.state_dir = self.root / "state"

    def run_hook(self, payload):
        env = os.environ.copy()
        env["AGENT_VERIFY_ON_STOP_STATE_DIR"] = str(self.state_dir)
        result = subprocess.run(
            [sys.executable, str(HOOK)],
            input=json.dumps(payload),
            capture_output=True,
            check=False,
            env=env,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout) if result.stdout else None

    def record_python_edit(self, session_id="codex-session"):
        self.run_hook({
            "hook_event_name": "PostToolUse",
            "session_id": session_id,
            "cwd": str(self.root),
            "tool_name": "apply_patch",
            "tool_input": {
                "command": "*** Begin Patch\n*** Update File: app/example.py\n*** End Patch"
            },
            "tool_response": {"is_error": False},
        })

    def stop(self, session_id="codex-session", cwd=None):
        return self.run_hook({
            "hook_event_name": "Stop",
            "session_id": session_id,
            "cwd": str(cwd or self.root),
            "stop_hook_active": False,
        })

    def test_codex_stop_blocks_after_an_unverified_patch(self):
        self.record_python_edit()

        result = self.stop()

        self.assertIsNotNone(result)
        self.assertEqual(result["decision"], "block")
        self.assertIn("app/example.py", result["reason"])
        self.assertIn("`pytest`", result["reason"])

    def test_failed_codex_verification_does_not_clear_the_edit(self):
        self.record_python_edit()
        self.run_hook({
            "hook_event_name": "PostToolUse",
            "session_id": "codex-session",
            "cwd": str(self.root),
            "tool_name": "Bash",
            "tool_input": {"command": "pytest"},
            "tool_response": {"exit_code": 1, "output": "1 failed"},
        })

        result = self.stop()

        self.assertIsNotNone(result)
        self.assertEqual(result["decision"], "block")

    def test_failed_codex_patch_does_not_record_an_edit(self):
        self.run_hook({
            "hook_event_name": "PostToolUse",
            "session_id": "failed-patch-session",
            "cwd": str(self.root),
            "tool_name": "apply_patch",
            "tool_input": {
                "command": "*** Begin Patch\n*** Update File: app/example.py\n*** End Patch"
            },
            "tool_response": {
                "status": "failed",
                "output": "apply_patch verification failed",
            },
        })

        self.assertIsNone(self.stop("failed-patch-session"))

    def test_successful_codex_verification_clears_the_edit(self):
        self.record_python_edit()
        self.run_hook({
            "hook_event_name": "PostToolUse",
            "session_id": "codex-session",
            "cwd": str(self.root),
            "tool_name": "Bash",
            "tool_input": {"command": "pytest"},
            "tool_response": {"exit_code": 0, "output": "1 passed"},
        })

        self.assertIsNone(self.stop())

    def test_repeated_patch_does_not_reset_the_stop_attempt_budget(self):
        self.record_python_edit()
        self.assertIsNotNone(self.stop())
        self.assertIsNotNone(self.stop())

        self.record_python_edit()

        self.assertIsNone(self.stop())

    def test_concurrent_codex_patches_preserve_every_pending_path(self):
        paths = ["app/example_%d.py" % index for index in range(128)]

        def record(path):
            self.run_hook({
                "hook_event_name": "PostToolUse",
                "session_id": "parallel-session",
                "cwd": str(self.root),
                "tool_name": "apply_patch",
                "tool_input": {
                    "command": "*** Begin Patch\n*** Update File: %s\n*** End Patch" % path
                },
                "tool_response": {"is_error": False},
            })

        with ThreadPoolExecutor(max_workers=64) as executor:
            list(executor.map(record, paths))

        state = json.loads((self.state_dir / "parallel-session.json").read_text())
        self.assertEqual(set(state["pending"]), set(paths))

    def test_claude_transcript_behavior_is_preserved(self):
        transcript = self.root / "claude.jsonl"
        transcript.write_text(json.dumps({
            "message": {
                "content": [{
                    "type": "tool_use",
                    "id": "edit-1",
                    "name": "Edit",
                    "input": {"file_path": "app/claude_example.py"},
                }]
            }
        }))

        result = self.run_hook({
            "hook_event_name": "Stop",
            "session_id": "claude-session",
            "cwd": str(self.root),
            "transcript_path": str(transcript),
            "stop_hook_active": False,
        })

        self.assertIsNotNone(result)
        self.assertIn("app/claude_example.py", result["reason"])

    def test_codex_ignores_a_documentation_only_patch(self):
        self.run_hook({
            "hook_event_name": "PostToolUse",
            "session_id": "docs-session",
            "cwd": str(self.root),
            "tool_name": "apply_patch",
            "tool_input": {
                "command": "*** Begin Patch\n*** Update File: README.md\n*** End Patch"
            },
            "tool_response": {"is_error": False},
        })

        self.assertIsNone(self.stop("docs-session"))

    def test_codex_ignores_a_patch_from_a_scratch_workspace(self):
        with tempfile.TemporaryDirectory(dir="/private/tmp") as scratch:
            Path(scratch, "pyproject.toml").touch()
            self.run_hook({
                "hook_event_name": "PostToolUse",
                "session_id": "scratch-session",
                "cwd": scratch,
                "tool_name": "apply_patch",
                "tool_input": {
                    "command": "*** Begin Patch\n*** Update File: app/example.py\n*** End Patch"
                },
                "tool_response": {"is_error": False},
            })

            self.assertIsNone(self.stop("scratch-session", cwd=scratch))


if __name__ == "__main__":
    unittest.main()
