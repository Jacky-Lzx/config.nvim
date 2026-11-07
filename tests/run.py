"""Isolated config checks with bounded lifetimes and a complete failure report."""

from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor
import argparse
import json
import os
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass, field
from pathlib import Path

from support.paths import ROOT, test_path
from support.tui_cases import FILES as TUI_FILES, SCENARIOS
from support.registry import validate_registry
from support.processes import (
    spawn,
    stop,
    release,
    cancel_all,
    reset_cancellation,
    LEDGER,
)
from support.features import FEATURES, tags

FULL = {"NVIM_TEST_SCENARIO": "full", "NVIM_TEST_ENABLE_THIRD_PARTY": "1"}


@dataclass
class Case:
    name: str
    command: list[str]
    env: dict[str, str] = field(default_factory=dict)
    timeout: float = 90
    skip: str = ""
    files: tuple[str, ...] = ()
    features: tuple[str, ...] = ()
    parallel: bool = False

    def label(self):
        variants = []
        for key, value in self.env.items():
            if key == "NVIM_TEST_SCENARIO":
                variants.append(value)
            elif key == "NVIM_TEST_REMAP_ACTIONS" and value == "1":
                variants.append("remapped")
            elif key in (
                "NVIM_TEST_LINK_FIRST",
                "NVIM_TEST_REFERENCE_FIRST",
                "BARS_TEST",
                "NVIM_WORKSPACE_ENABLED",
            ):
                variants.append(key.lower() + "=" + value)
            elif key not in (
                "NVIM_TEST_ENABLE_THIRD_PARTY",
                "NVIM_TEST_ISOLATE_PLUGINS",
            ):
                variants.append(
                    key.removeprefix("NVIM_TEST_").removeprefix("NVIM_").lower()
                    + "="
                    + value
                )
        return self.name + ("[" + ",".join(variants) + "]" if variants else "")


def lua(name, env=None):
    return Case(
        name,
        [
            "nvim",
            "--headless",
            "-u",
            "NONE",
            "-i",
            "NONE",
            "--noplugin",
            "-l",
            str(ROOT / "tests/support/checked.lua"),
            str(test_path(name + ".lua")),
        ],
        env or {},
        files=(test_path(name + ".lua").relative_to(ROOT).as_posix(),),
        features=tags(name),
    )


def startup(name, env=None):
    return Case(
        name,
        [
            "nvim",
            "--headless",
            "-i",
            "NONE",
            "--cmd",
            "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/support/setup.lua')",
            "-u",
            str(ROOT / "init.lua"),
            "-c",
            "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/"
            + test_path(name + ".lua").relative_to(ROOT).as_posix()
            + "')",
        ],
        env or {},
        files=(test_path(name + ".lua").relative_to(ROOT).as_posix(),),
        features=tags(name),
    )


def python(name, *args, env=None):
    return Case(
        name + (":" + ":".join(args) if args else ""),
        [sys.executable, str(test_path(name + ".py")), *args],
        env or {},
        timeout=150,
        features=tags(name),
        files=tuple(
            path.relative_to(ROOT).as_posix()
            for path in (
                test_path(name + ".py"),
                test_path(name + ".py").with_suffix(".lua"),
            )
            if path.is_file()
        ),
    )


def tui(name, env=None):
    effective = dict(env or {})
    effective.update(SCENARIOS[name].env)
    case = python("tui", name, env=effective)
    case.files += (test_path(TUI_FILES[name]).relative_to(ROOT).as_posix(),)
    case.features = tags(name)
    return case


def suites():
    native = [python("runner_checks"), lua("smoke")]
    native += [
        lua(name)
        for name in [
            "plugin_bootstrap",
            "profiling",
            "lockfile",
            "schema",
            "selection",
            "project",
            "info",
            "config",
            "platform",
            "core",
            "bindings",
            "action_contracts",
            "clipboard",
            "diagnostics",
            "completion",
            "math_conditions",
            "latex_forward_search",
            "commands",
            "python",
            "tasks",
            "integrations",
            "image_activation",
            "tooling",
            "toolchain",
            "lsp_config",
            "files",
        ]
    ]
    for case in native:
        case.env["NVIM_TEST_ISOLATE_PLUGINS"] = "1"
        case.parallel = True

    # Real personal defaults, without re-enabling disabled declarations.
    integration = [
        lua("environment"),
        lua("per_plugin_flags"),
        startup("personal_startup"),
        startup("demand_startup"),
        startup(
            "demand_startup",
            {"NVIM_TEST_SCENARIO": "python", "NVIM_DEMAND_COMMANDS": "1"},
        ),
        tui("demand"),
        tui("bigfile"),
        startup("markdown_demand"),
        startup("markdown_demand", {"NVIM_TEST_MARKDOWN_WORKSPACE": "1"}),
        tui("markdown_demand"),
        tui("markdown_demand", {"NVIM_TEST_MARKDOWN_WORKSPACE": "1"}),
        tui("markdown_direct"),
        tui("markdown_tools"),
    ]
    integration.append(lua("preview_policy", {"NVIM_TEST_SCENARIO": "writing"}))
    integration.append(lua("document_render", {"NVIM_TEST_SCENARIO": "writing"}))
    integration += [
        lua(name)
        for name in [
            "mapping_contracts",
            "keymap_panels",
            "lifecycle",
            "lint_runtime",
            "format_runtime",
            "treesitter_runtime",
            "project_plugins",
            "obsidian_local",
            "notifications",
            "image_preview",
            "project_snippets",
            "snippet_collections",
            "latex_snippet_collections",
        ]
    ]
    integration += [
        python(name)
        for name in (
            "open_at_cursor_tui",
            "project_plugins_tui",
            "obsidian_tools_tui",
            "project_snippets_tui",
        )
    ]
    integration += [
        python("file_tools_tui", variant)
        for variant in ("tree", "dashboard-picker", "dashboard-tree")
    ]
    integration.append(
        python("file_tools_tui", "tree", env={"NVIM_TEST_REMAP_ACTIONS": "1"})
    )
    integration += [
        tui(name)
        for name in (
            "notifications",
            "completion_input",
            "annotations",
            "keymaps",
            "nested_keymaps",
            "health",
        )
    ]
    integration += [tui("tasks", {"NVIM_TEST_SCENARIO": "tasks"})]
    integration += [tui("completion_policy")]
    integration += [
        tui("keymaps", {"NVIM_TEST_REMAP_ACTIONS": "1"}),
        tui("tasks", {"NVIM_TEST_SCENARIO": "tasks", "NVIM_TEST_REMAP_ACTIONS": "1"}),
    ]
    integration += [
        tui(name)
        for name in [
            "image_plain",
            "image_edit",
            "image_existing",
            "image_tex_reference",
            "image_typst_reference",
            "image_markdown_formula",
            "image_disabled",
            "image_formula",
            "image_file",
        ]
    ]

    # Fixed selections opt into optional owners for broader compatibility checks.
    compatibility = [lua("environment")]
    compatibility += [
        lua(name)
        for name in [
            "open_at_cursor",
            "toggles",
            "comments",
            "folding",
            "rust",
            "tools_runtime",
            "lsp_tools",
            "bars",
            "semantic_icons",
            "git_tools",
            "column_guide",
            "toolchain_backend",
            "tasks_session",
            "workspaces",
            "plugin_manifest",
            "plugin_sources",
        ]
    ]
    compatibility += [
        lua("lsp_tools", {"NVIM_TEST_LINK_FIRST": "1"}),
        lua("lsp_tools", {"NVIM_TEST_REFERENCE_FIRST": "1"}),
        lua("bars", {"BARS_TEST": "before"}),
    ]
    for scenario in ("full", "minimal", "python", "writing"):
        env = {"NVIM_TEST_SCENARIO": scenario}
        compatibility += [
            lua("column_guide", dict(env, NVIM_COLUMN_GUIDE_STARTUP="1")),
            startup("folding_startup", env),
            startup("startup", env),
        ]
    compatibility += [startup("input", {"NVIM_TEST_SCENARIO": "minimal"})]
    compatibility += [
        startup(name, {"NVIM_TEST_SCENARIO": "writing"})
        for name in ("latex_highlighting", "latex_tools")
    ]
    query = startup("latex_queries", {"NVIM_TEST_SCENARIO": "writing"})
    query.command[-1] = (
        "lua local ok, err = pcall(dofile, vim.env.NVIM_CONFIG_ROOT .. '/tests/integration/latex_queries.lua'); "
        "if not ok then io.stderr:write(tostring(err)); vim.cmd('cquit 1') end"
    )
    query.command.append("+qa!")
    compatibility.append(query)
    compatibility += [
        lua("workspaces", {"NVIM_WORKSPACE_ENABLED": "0"}),
        python("workspace_tui"),
    ]
    compatibility += [
        tui(name)
        for name in (
            "notification_picker",
            "native_utilities",
            "python_environment",
            "toolchain",
        )
    ]
    compatibility += [
        lua(name, {"NVIM_TEST_SCENARIO": "writing"})
        for name in ("snippets", "latex_snippets")
    ]
    compatibility += [
        python(name)
        for name in ("latex_snippets_tui", "snippets_tui", "treesitter_tui")
    ]
    compatibility += [
        tui("copilot"),
        tui("copilot", {"NVIM_TEST_COPILOT_MODE": "staged"}),
    ]
    compatibility += [tui("motion"), tui("motion", {"NVIM_TEST_SCENARIO": "minimal"})]
    compatibility += [
        tui(name)
        for name in [
            "boundaries",
            "boundaries_files",
            "editing",
            "editing_input",
            "completion",
            "ui_tools",
            "bars",
            "folding",
        ]
    ]
    for case in compatibility:
        case.env = dict(FULL, **case.env)
        if case.name in ("workspaces", "workspace_tui"):
            # These cases provide their own config.selection fixture before setup.
            case.env["NVIM_TEST_SCENARIO"] = "default"

    # Actual local language servers are explicit acceptance checks. No downloads.
    acceptance = [python("lsp_native_tui", env=FULL)]
    fallback = lua("notifications", {"NVIM_TEST_REMOTE_FALLBACK": "1"})
    fallback.name = "notifications:installed-fallback"
    acceptance.append(fallback)
    return {
        "native": native,
        "integration": integration,
        "compatibility": compatibility,
        "acceptance": acceptance,
        "migration": [lua("snippet_migration")],
    }


def environment(case, directory):
    env = dict(os.environ)
    for name in list(env):
        if name.startswith(("NVIM_TEST_", "NVIM_STARTUP_")) or name in (
            "PROF",
            "BARS_TEST",
            "NVIM_COLUMN_GUIDE_STARTUP",
            "NVIM_PLUGIN_LOCKFILE",
            "NVIM_PLUGIN_ROOT",
        ):
            env.pop(name)
    for name in ("NVIM", "NVIM_LISTEN_ADDRESS", "NVIM_APPNAME", "VIMINIT", "EXINIT"):
        env.pop(name, None)
    for name in ("tmp", "runtime", "config"):
        (directory / name).mkdir(parents=True, exist_ok=True)
    env.update(
        NVIM_CONFIG_ROOT=str(ROOT),
        NVIM_TEST_TMP=str(directory),
        NVIM_TEST_ARTIFACT_DIR=str(directory),
        NVIM_SMOKE_TEST="1",
        NVIM_TEST_ENABLE_THIRD_PARTY="0",
        XDG_CACHE_HOME=str(directory / "cache"),
        XDG_STATE_HOME=str(directory / "state"),
        NVIM_LOG_FILE=str(directory / "nvim.log"),
        XDG_CONFIG_HOME=str(directory / "config"),
        XDG_RUNTIME_DIR=str(directory / "runtime"),
        TMPDIR=str((directory / "tmp").resolve()),
        PYTHONDONTWRITEBYTECODE="1",
        SSH_CONNECTION="",
        NVIM_PLUGIN_LOCKFILE=str(directory / "plugin-tools-lock.json"),
    )
    env.setdefault(
        "NVIM_PLUGIN_TOOLS_PATH",
        str(Path.home() / "Documents/Github/nvim_plugins/plugin-tools.nvim"),
    )
    env.update(case.env)
    env[LEDGER] = str(directory / "process-groups.jsonl")
    # Tests may explicitly import a pure plugin module while keeping startup isolated.
    env["NVIM_TEST_PLUGIN_FIXTURES"] = env.get(
        "NVIM_DEV_PLUGIN_ROOT", str(Path.home() / "Documents/Github/nvim_plugins")
    )
    if env.get("NVIM_TEST_ISOLATE_PLUGINS") == "1":
        env.update(
            XDG_DATA_HOME=str(directory / "data"),
            NVIM_DEV_PLUGIN_ROOT=str(directory / "missing-development"),
        )
    if env.get("NVIM_TEST_REMOTE_FALLBACK") == "1":
        env["NVIM_DEV_PLUGIN_ROOT"] = str(directory / "missing-development")
    return env


def execute(case, directory):
    directory.mkdir(parents=True)
    shutil.copyfile(
        ROOT / "plugin-tools-lock.json", directory / "plugin-tools-lock.json"
    )
    (directory / "sample.tex").write_text(
        "\\documentclass{article}\n\\begin{document}\n\\( x + y \\)\n\\end{document}\n"
    )
    (directory / "sample.py").write_text('print("hello")\n')
    (directory / "sample.vue").write_text(
        '<script setup lang="ts">const count = 1</script>\n'
    )
    env = environment(case, directory)
    reason = case.skip
    if env.get("NVIM_TEST_REMOTE_FALLBACK") == "1":
        query = subprocess.run(
            [
                "nvim",
                "--headless",
                "-u",
                "NONE",
                "-i",
                "NONE",
                "--noplugin",
                "--cmd",
                "lua io.stdout:write(vim.fn.stdpath('data'))",
                "+qa",
            ],
            env=env,
            check=False,
            capture_output=True,
            text=True,
            timeout=15,
        )
        if query.returncode == 0:
            installed = Path(query.stdout) / "plugin-tools"
            missing = [
                name
                for name in (
                    "notification-tools.nvim",
                    "input-tools.nvim",
                    "ui-tools.nvim",
                    "selection-tools.nvim",
                )
                if not (installed / name).is_dir()
            ]
            if missing:
                reason = "installed fallback checkouts absent: " + ", ".join(missing)
    record = {
        "name": case.label(),
        "directory": str(directory),
        "command": case.command,
        "env": case.env,
    }
    if reason:
        return dict(record, status="skip", reason=reason, seconds=0)
    started = time.monotonic()
    try:
        with (directory / "output.log").open("wb") as log:
            process = spawn(
                case.command,
                cwd=ROOT,
                env=env,
                stdout=log,
                stderr=subprocess.STDOUT,
                start_new_session=True,
            )
            try:
                code = process.wait(timeout=case.timeout)
                record.update(status="pass" if code == 0 else "fail", exit_code=code)
                if code:
                    record["reason"] = f"exit {code}"
            except subprocess.TimeoutExpired:
                stop(process, env[LEDGER])
                record.update(status="fail", reason=f"timeout after {case.timeout}s")
            except BaseException:
                stop(process, env[LEDGER])
                raise
            finally:
                release(process)
    except OSError as error:
        record.update(status="fail", reason=str(error))
    record["seconds"] = round(time.monotonic() - started, 3)
    return record


def git(directory, *args):
    result = subprocess.run(
        ["git", "-C", str(directory), *args],
        check=False,
        capture_output=True,
        text=True,
        timeout=10,
    )
    return result.stdout.strip() if result.returncode == 0 else None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    available = suites()
    parser.add_argument("suite", nargs="?", default="all", choices=[*available, "all"])
    parser.add_argument(
        "--keep",
        action="store_true",
        help="Keep all logs and isolated case state on success",
    )
    parser.add_argument(
        "--filter",
        default="",
        help="Run only cases whose qualified name contains this text",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List selected cases without starting Neovim",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Validate case identities and script registration",
    )
    parser.add_argument(
        "--feature",
        action="append",
        choices=sorted(FEATURES),
        default=[],
        help="Select cases covering a feature; repeat to select several",
    )
    parser.add_argument(
        "--jobs",
        type=int,
        default=1,
        help="Maximum parallel isolated native checks; PTY/integration cases stay serial",
    )
    parser.add_argument(
        "--durations", type=int, default=0, help="Report this many slowest cases"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print successful case logs as well as results",
    )
    args = parser.parse_args()
    if args.jobs < 1 or args.durations < 0:
        parser.error("jobs must be positive and durations nonnegative")
    if args.check:
        validate_registry(ROOT, available)
        print("Test registration passed")
        return False
    selected = (
        ["native", "integration", "compatibility", "acceptance"]
        if args.suite == "all"
        else [args.suite]
    )
    cases = [
        (group, case)
        for group in selected
        for case in available[group]
        if args.filter in group + "/" + case.label()
        and (not args.feature or set(args.feature).intersection(case.features))
    ]
    if not cases:
        parser.error("No matching checks")
    labels = [group + "/" + case.label() for group, case in cases]
    if len(labels) != len(set(labels)):
        parser.error("Duplicate qualified case labels")
    if args.list:
        for label in labels:
            print(label)
        return False
    directory = Path(tempfile.mkdtemp(prefix="nvim-smoke-"))
    version = subprocess.run(
        ["nvim", "--version"], check=False, capture_output=True, text=True, timeout=10
    )
    summary = {
        "suite": args.suite,
        "config_commit": git(ROOT, "rev-parse", "HEAD"),
        "config_changes": git(ROOT, "status", "--short"),
        "nvim": (version.stdout.splitlines() or [version.stderr])[0],
        "results": [],
        "jobs": args.jobs,
        "features": args.feature,
    }
    print(
        f"Testing {summary['nvim']}; config {summary['config_commit']}; artifacts {directory}",
        flush=True,
    )
    interrupted = False
    started = time.monotonic()
    reset_cancellation()
    pool = ThreadPoolExecutor(max_workers=args.jobs) if args.jobs > 1 else None
    futures = {}
    for index, (group, case) in enumerate(cases, 1):
        print(f"[{index}/{len(cases)}] {group}/{case.label()}", flush=True)
        case_directory = (
            directory / f"{index:03d}-{group}-{case.name.replace(':', '-')}"
        )
        try:
            if pool and group == "native" and case.parallel and index not in futures:
                # Submit only this contiguous native batch. A serial declaration
                # is a barrier for both earlier and later parallel work.
                for offset in range(index - 1, len(cases)):
                    pending_group, pending = cases[offset]
                    if pending_group != "native" or not pending.parallel:
                        break
                    number = offset + 1
                    target = (
                        directory
                        / f"{number:03d}-{pending_group}-{pending.name.replace(':', '-')}"
                    )
                    futures[number] = pool.submit(execute, pending, target)
            result = (
                futures[index].result()
                if index in futures
                else execute(case, case_directory)
            )
        except KeyboardInterrupt:
            interrupted = True
            for future in futures.values():
                future.cancel()
            cancel_all()
            result = {
                "name": case.label(),
                "directory": str(case_directory),
                "status": "fail",
                "reason": "interrupted",
                "seconds": 0,
                "command": case.command,
            }
        except (OSError, subprocess.SubprocessError, ValueError) as error:
            result = {
                "name": case.name,
                "directory": str(case_directory),
                "status": "fail",
                "reason": str(error),
                "seconds": 0,
                "command": case.command,
            }
        result["suite"] = group
        snapshot = Path(result["directory"]) / "environment.json"
        if snapshot.exists():
            try:
                plugins = json.loads(snapshot.read_text())
                for plugin in plugins:
                    plugin["commit"] = git(plugin["directory"], "rev-parse", "HEAD")
                    plugin["changes"] = git(plugin["directory"], "status", "--short")
                result["plugins"] = plugins
            except (OSError, subprocess.SubprocessError, ValueError) as error:
                result.update(
                    status="fail", reason="Environment snapshot failed: " + str(error)
                )
        summary["results"].append(result)
        print(
            f"  {result['status'].upper()} ({result['seconds']:.2f}s) "
            + result.get("reason", ""),
            flush=True,
        )
        log = Path(result["directory"]) / "output.log"
        if log.exists() and (args.verbose or result["status"] != "pass"):
            content = log.read_text(errors="replace")
            print(
                content if result["status"] == "pass" else content[-10000:],
                end="",
                flush=True,
            )
        case_directory.mkdir(parents=True, exist_ok=True)
        (case_directory / "result.json").write_text(json.dumps(result, indent=2) + "\n")
        summary["interrupted"] = interrupted
        (directory / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
        if interrupted:
            break
    if pool:
        pool.shutdown(wait=True, cancel_futures=True)
    reset_cancellation()
    summary["wall_seconds"] = round(time.monotonic() - started, 3)
    (directory / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    if args.durations:
        print("Slowest cases:")
        for result in sorted(
            summary["results"], key=lambda r: r["seconds"], reverse=True
        )[: args.durations]:
            print(f"  {result['seconds']:.3f}s {result['suite']}/{result['name']}")
    failed = [r for r in summary["results"] if r["status"] == "fail"]
    skipped = [r for r in summary["results"] if r["status"] == "skip"]
    print(
        f"\nChecks: {len(summary['results']) - len(failed) - len(skipped)} passed, {len(failed)} failed, {len(skipped)} skipped."
    )
    for result in failed + skipped:
        print(
            f"  {result['status'].upper()}: {result['suite']}/{result['name']} "
            + result.get("reason", "")
        )
    if failed or args.keep:
        print(f"Logs and summary retained: {directory}")
    else:
        shutil.rmtree(directory)
    return 130 if interrupted else bool(failed)


if __name__ == "__main__":

    def terminate(signum, frame):
        raise KeyboardInterrupt

    signal.signal(signal.SIGTERM, terminate)
    sys.exit(main())
