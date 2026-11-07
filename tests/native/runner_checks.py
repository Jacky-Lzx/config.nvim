"""Guard failure aggregation, process timeouts and per-case state isolation."""

import contextlib
import io
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from run import Case, environment, execute, main


class RunnerChecks(unittest.TestCase):
    def test_main_reports_all_failures_and_keeps_evidence(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp) / "run"
            directory.mkdir()
            cases = [
                Case("broken", [sys.executable, "-c", "raise SystemExit(7)"]),
                Case("next", [sys.executable, "-c", "print('completed')"]),
            ]
            with (
                patch("run.suites", return_value={"native": cases}),
                patch("run.tempfile.mkdtemp", return_value=str(directory)),
                patch.object(sys, "argv", ["run.py", "native"]),
                contextlib.redirect_stdout(io.StringIO()),
            ):
                self.assertTrue(main())
            summary = json.loads((directory / "summary.json").read_text())
            self.assertEqual(
                [r["status"] for r in summary["results"]], ["fail", "pass"]
            )
            self.assertTrue((directory / "001-native-broken/output.log").exists())

    def test_failure_does_not_prevent_next_case(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            failed = execute(
                Case(
                    "broken",
                    [
                        sys.executable,
                        "-c",
                        "print('failure evidence'); raise SystemExit(3)",
                    ],
                ),
                root / "broken",
            )
            passed = execute(
                Case("next", [sys.executable, "-c", "print('still ran')"]),
                root / "next",
            )
            self.assertEqual(
                (failed["status"], failed["exit_code"], passed["status"]),
                ("fail", 3, "pass"),
            )
            self.assertIn("failure evidence", (root / "broken/output.log").read_text())
            self.assertIn("still ran", (root / "next/output.log").read_text())
            self.assertNotEqual(
                environment(Case("a", []), root / "broken")["XDG_STATE_HOME"],
                environment(Case("b", []), root / "next")["XDG_STATE_HOME"],
            )

    def test_timeout_and_missing_executable_are_failures(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            result = execute(
                Case(
                    "timeout",
                    [sys.executable, "-c", "import time; time.sleep(10)"],
                    timeout=0.1,
                ),
                root / "slow",
            )
            self.assertEqual(result["status"], "fail")
            self.assertIn("timeout", result["reason"])
            result = execute(Case("missing", [str(root / "absent")]), root / "missing")
            self.assertEqual(result["status"], "fail")

    def test_explicit_skip_and_environment_overrides(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            result = execute(
                Case("optional", [], skip="disabled fixture"), root / "skip"
            )
            self.assertEqual(
                (result["status"], result["reason"]), ("skip", "disabled fixture")
            )
            with patch.dict(
                os.environ,
                {"NVIM_TEST_REFERENCE_FIRST": "1", "NVIM_TEST_REMAP_ACTIONS": "1"},
            ):
                env = environment(Case("personal", []), root)
                self.assertNotIn("NVIM_TEST_REFERENCE_FIRST", env)
                self.assertNotIn("NVIM_TEST_REMAP_ACTIONS", env)
                self.assertEqual(env["NVIM_TEST_ENABLE_THIRD_PARTY"], "0")
                env = environment(
                    Case("fixture", [], {"NVIM_TEST_REMAP_ACTIONS": "1"}), root
                )
                self.assertEqual(env["NVIM_TEST_REMAP_ACTIONS"], "1")


if __name__ == "__main__":
    unittest.main()
