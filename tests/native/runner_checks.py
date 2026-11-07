"""Guard failure aggregation, process timeouts and per-case state isolation."""

import contextlib
import io
import json
import os
import sys
import time
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from run import Case, environment, execute, main
from support.registry import validate_registry
from support.processes import spawn
from support.tui_cases import Stage
from support.tui_protocol import event


class RunnerChecks(unittest.TestCase):
    def test_parallel_interrupt_cancels_queued_work_and_stops_active_groups(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            directory = root / "run"
            directory.mkdir()
            code = "import os,sys,time; from pathlib import Path; Path(sys.argv[1]).write_text(str(os.getpid())); time.sleep(60)"
            cases = [
                Case(
                    str(i),
                    [sys.executable, "-c", code, str(root / f"pid-{i}")],
                    parallel=True,
                )
                for i in range(3)
            ]

            def interrupt_when_running(*args, **kwargs):
                deadline = time.monotonic() + 5
                while len(list(root.glob("pid-*"))) < 2 and time.monotonic() < deadline:
                    time.sleep(0.01)
                raise KeyboardInterrupt

            with (
                patch("run.suites", return_value={"native": cases}),
                patch("run.tempfile.mkdtemp", return_value=str(directory)),
                patch(
                    "concurrent.futures.Future.result",
                    side_effect=interrupt_when_running,
                ),
                patch.object(sys, "argv", ["run.py", "native", "--jobs", "2"]),
                contextlib.redirect_stdout(io.StringIO()),
            ):
                self.assertEqual(main(), 130)
            self.assertEqual(
                len(list(root.glob("pid-*"))),
                2,
                "Queued case started after interruption",
            )
            for marker in root.glob("pid-*"):
                with self.assertRaises(ProcessLookupError):
                    os.kill(int(marker.read_text()), 0)

    def test_parallel_native_checks_overlap_and_serial_case_waits(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            directory = root / "run"
            directory.mkdir()
            code = (
                "import sys,time; from pathlib import Path; "
                "root=Path(sys.argv[1]); name=sys.argv[2]; (root/name).touch(); "
                "deadline=time.monotonic()+5; "
                "\nwhile len(list(root.glob('ready-*')))<2 and time.monotonic()<deadline: time.sleep(.01)\n"
                "assert len(list(root.glob('ready-*')))==2; (root/(name+'-done')).touch()"
            )
            cases = [
                Case(name, [sys.executable, "-c", code, str(root), name], parallel=True)
                for name in ("ready-a", "ready-b")
            ]
            # Count only ready files when waiting: completion markers have a distinct suffix.
            code = code.replace(
                "root.glob('ready-*')",
                "(p for p in root.glob('ready-*') if not p.name.endswith('-done'))",
            )
            for case in cases:
                case.command[2] = code
            serial = (
                "from pathlib import Path; p=Path("
                + repr(str(root))
                + "); assert len(list(p.glob('*-done')))==2"
            )
            cases.append(
                Case(
                    "serial-pty",
                    [sys.executable, "-c", serial + "; (p/'serial-done').touch()"],
                )
            )
            cases.append(
                Case(
                    "after-serial",
                    [
                        sys.executable,
                        "-c",
                        "from pathlib import Path; assert Path("
                        + repr(str(root / "serial-done"))
                        + ").exists()",
                    ],
                    parallel=True,
                )
            )
            with (
                patch("run.suites", return_value={"native": cases}),
                patch("run.tempfile.mkdtemp", return_value=str(directory)),
                patch.object(
                    sys, "argv", ["run.py", "native", "--jobs", "2", "--keep"]
                ),
                contextlib.redirect_stdout(io.StringIO()),
            ):
                self.assertFalse(main())
            results = json.loads((directory / "summary.json").read_text())["results"]
            self.assertEqual([r["name"] for r in results], [c.name for c in cases])
            self.assertTrue(all(r["status"] == "pass" for r in results))

    def test_feature_selection_includes_configured_and_optional_variants(self):
        with (
            patch.object(
                sys, "argv", ["run.py", "all", "--feature", "completion", "--list"]
            ),
            patch(
                "run.execute",
                side_effect=AssertionError("Feature listing executed a case"),
            ),
            contextlib.redirect_stdout(io.StringIO()) as output,
        ):
            self.assertFalse(main())
        text = output.getvalue()
        self.assertIn("native/completion", text)
        self.assertIn("integration/tui:completion_policy[writing]", text)
        self.assertIn("copilot_mode=staged", text)
        self.assertNotIn("file_tools_tui", text)

    def test_stage_protocol_waits_for_complete_input_and_dispatches_once(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            stage = Stage("stage", input_file="input", resize_file="resize")
            (root / "stage").write_text("resize")
            self.assertIsNone(event(stage, root, set()))
            (root / "input").write_bytes(b"\x1b[A")
            (root / "resize").write_text("160")
            self.assertEqual(event(stage, root, set()), ("resize", b"\x1b[A", 160))
            self.assertIsNone(event(stage, root, {"resize"}))
            self.assertFalse((root / "resize").exists())
            (root / "stage").write_text('confirm\n"unfinished')
            self.assertIsNone(event(Stage("stage"), root, set()))
            (root / "stage").write_text('confirm\n"<CR>"')
            self.assertEqual(
                event(Stage("stage", vim_keys=True), root, set()),
                ("confirm", b"\r", None),
            )

    def test_nested_failure_keeps_terminal_state_and_progress(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            code = (
                "import sys; from pathlib import Path; "
                f"sys.path.insert(0, {str(Path(__file__).resolve().parents[1])!r}); "
                "from support.artifacts import workspace, Transcript, record_stage; "
                "\nwith workspace(prefix='nested-') as directory:\n"
                " output=Transcript(); output.extend(b'\\x1b[31mVISIBLE FAILURE\\x1b[0m'); "
                "record_stage('confirm'); Path(directory, 'snapshot.json').write_text('{}'); "
                "raise AssertionError('injected failure')"
            )
            result = execute(
                Case("evidence", [sys.executable, "-c", code]), root / "case"
            )
            self.assertEqual(result["status"], "fail")
            nested = next((root / "case").glob("nested-*"))
            self.assertEqual(
                (nested / "terminal.bin").read_bytes(),
                b"\x1b[31mVISIBLE FAILURE\x1b[0m",
            )
            self.assertIn("VISIBLE FAILURE", (nested / "terminal.txt").read_text())
            self.assertEqual(
                json.loads((nested / "stage.json").read_text())["stage"], "confirm"
            )
            self.assertTrue((nested / "snapshot.json").exists())

    def test_timeout_cleans_child_in_a_new_session_without_ps(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            marker = root / "child.pid"
            code = (
                "import sys,time; from pathlib import Path; "
                f"sys.path.insert(0, {str(Path(__file__).resolve().parents[1])!r}); "
                "from support.processes import spawn; "
                "child=spawn([sys.executable, '-c', 'import time; time.sleep(60)']); "
                f"Path({str(marker)!r}).write_text(str(child.pid)); time.sleep(60)"
            )
            try:
                with patch(
                    "support.processes.subprocess.run",
                    side_effect=PermissionError("ps unavailable"),
                ):
                    result = execute(
                        Case("sessions", [sys.executable, "-c", code], timeout=0.8),
                        root / "case",
                    )
                self.assertEqual(result["status"], "fail")
                self.assertIn("timeout", result["reason"])
                pid = int(marker.read_text())
                deadline = time.monotonic() + 3
                while time.monotonic() < deadline:
                    try:
                        os.kill(pid, 0)
                    except ProcessLookupError:
                        break
                    time.sleep(0.02)
                else:
                    self.fail("Detached child survived timeout cleanup")
            finally:
                if marker.exists():
                    try:
                        os.kill(int(marker.read_text()), 9)
                    except ProcessLookupError:
                        pass

    def test_interrupt_stops_process_and_retains_partial_summary(self):
        process = spawn([sys.executable, "-c", "import time; time.sleep(60)"])
        wait = process.wait
        calls = 0

        def interrupt_once(*args, **kwargs):
            nonlocal calls
            calls += 1
            if calls == 1:
                raise KeyboardInterrupt
            return wait(*args, **kwargs)

        process.wait = interrupt_once
        with tempfile.TemporaryDirectory() as tmp:
            with patch("run.spawn", return_value=process):
                with self.assertRaises(KeyboardInterrupt):
                    execute(Case("interrupt", []), Path(tmp) / "case")
        self.assertIsNotNone(process.poll())
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            with (
                patch(
                    "run.suites",
                    return_value={"native": [Case("interrupt", []), Case("later", [])]},
                ),
                patch("run.execute", side_effect=KeyboardInterrupt),
                patch("run.tempfile.mkdtemp", return_value=str(directory)),
                patch.object(sys, "argv", ["run.py", "native"]),
                contextlib.redirect_stdout(io.StringIO()),
            ):
                self.assertEqual(main(), 130)
            summary = json.loads((directory / "summary.json").read_text())
            self.assertTrue(summary["interrupted"])
            self.assertEqual(len(summary["results"]), 1)
            self.assertEqual(summary["results"][0]["reason"], "interrupted")

    def test_variant_labels_are_unique_and_listing_does_not_execute(self):
        from run import suites

        cases = suites()
        labels = [
            group + "/" + case.label()
            for group, entries in cases.items()
            for case in entries
        ]
        self.assertEqual(len(labels), len(set(labels)))
        with (
            patch.object(
                sys,
                "argv",
                ["run.py", "integration", "--filter", "markdown_demand", "--list"],
            ),
            patch("run.execute", side_effect=AssertionError("Listing executed a test")),
            contextlib.redirect_stdout(io.StringIO()) as output,
        ):
            self.assertFalse(main())
        self.assertIn("markdown_workspace=1", output.getvalue())

    def test_registry_rejects_omissions_duplicates_and_missing_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "tests").mkdir()
            (root / "tests/roles.json").write_text('{"support": {}, "manual": {}}')
            script = root / "tests/example.lua"
            script.touch()
            case = Case("example", [], files=("tests/example.lua",))
            validate_registry(root, {"native": [case]})
            with self.assertRaisesRegex(ValueError, "Duplicate case"):
                validate_registry(root, {"native": [case, case]})
            orphan = root / "tests/forgotten.lua"
            orphan.touch()
            with self.assertRaisesRegex(ValueError, "Unregistered test scripts"):
                validate_registry(root, {"native": [case]})
            orphan.unlink()
            script.unlink()
            with self.assertRaisesRegex(ValueError, "Missing registered script"):
                validate_registry(root, {"native": [case]})

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
                {
                    "NVIM_TEST_REFERENCE_FIRST": "1",
                    "NVIM_TEST_DISABLE_BINDINGS": "1",
                    "NVIM": "/foreign/rpc-socket",
                    "NVIM_APPNAME": "foreign-config",
                    "VIMINIT": "foreign-init",
                },
            ):
                env = environment(Case("personal", []), root)
                self.assertNotIn("NVIM_TEST_REFERENCE_FIRST", env)
                self.assertNotIn("NVIM_TEST_DISABLE_BINDINGS", env)
                for key in ("NVIM", "NVIM_APPNAME", "VIMINIT"):
                    self.assertNotIn(key, env)
                self.assertEqual(Path(env["XDG_CONFIG_HOME"]), root / "config")
                self.assertEqual(Path(env["TMPDIR"]), (root / "tmp").resolve())
                self.assertEqual(env["NVIM_TEST_ENABLE_THIRD_PARTY"], "0")
                env = environment(
                    Case("fixture", [], {"NVIM_TEST_DISABLE_BINDINGS": "1"}), root
                )
                self.assertEqual(env["NVIM_TEST_DISABLE_BINDINGS"], "1")


if __name__ == "__main__":
    unittest.main()
