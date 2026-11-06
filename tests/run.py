"""Isolated config checks with bounded lifetimes and a complete failure report."""

from __future__ import annotations

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

ROOT = Path(__file__).resolve().parents[1]
FULL = {"NVIM_TEST_SCENARIO": "full", "NVIM_TEST_ENABLE_THIRD_PARTY": "1"}


@dataclass
class Case:
    name: str
    command: list[str]
    env: dict[str, str] = field(default_factory=dict)
    timeout: float = 90
    skip: str = ""

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
            str(ROOT / "tests/checked.lua"),
            str(ROOT / "tests" / (name + ".lua")),
        ],
        env or {},
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
            "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')",
            "-u",
            str(ROOT / "init.lua"),
            "-c",
            "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/" + name + ".lua')",
        ],
        env or {},
    )


def python(name, *args, env=None):
    return Case(
        name + (":" + ":".join(args) if args else ""),
        [sys.executable, str(ROOT / "tests" / (name + ".py")), *args],
        env or {},
        timeout=150,
    )


def tui(name, env=None):
    return python("tui", name, env=env)


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

    # Real personal defaults, without re-enabling disabled declarations.
    integration = [
        lua("environment"),
        lua("per_plugin_flags"),
        startup("personal_startup"),
        startup("demand_startup"),
        startup("demand_startup", {"NVIM_TEST_SCENARIO": "python", "NVIM_DEMAND_COMMANDS": "1"}),
        tui("demand"),
        startup("markdown_demand"),
        tui("markdown_demand"),
        tui("markdown_direct"),
    ]
    integration += [
        lua(name)
        for name in [
            "mapping_contracts",
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
            "project_snippets_tui",
        )
    ]
    integration += [
        tui(name)
        for name in ("notifications", "completion_input", "annotations", "keymaps")
    ]
    integration += [tui("tasks", {"NVIM_TEST_SCENARIO": "tasks"})]
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
        "lua local ok, err = pcall(dofile, vim.env.NVIM_CONFIG_ROOT .. '/tests/latex_queries.lua'); "
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
    env.update(
        NVIM_CONFIG_ROOT=str(ROOT),
        NVIM_TEST_TMP=str(directory),
        NVIM_SMOKE_TEST="1",
        NVIM_TEST_ENABLE_THIRD_PARTY="0",
        XDG_CACHE_HOME=str(directory / "cache"),
        XDG_STATE_HOME=str(directory / "state"),
        NVIM_LOG_FILE=str(directory / "nvim.log"),
        SSH_CONNECTION="",
        NVIM_PLUGIN_LOCKFILE=str(directory / "plugin-tools-lock.json"),
    )
    env.setdefault(
        "NVIM_PLUGIN_TOOLS_PATH",
        str(Path.home() / "Documents/Github/nvim_plugins/plugin-tools.nvim"),
    )
    env.update(case.env)
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
            process = subprocess.Popen(
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
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
                record.update(status="fail", reason=f"timeout after {case.timeout}s")
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
    args = parser.parse_args()
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
    ]
    if not cases:
        parser.error("No matching checks")
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
    }
    print(
        f"Testing {summary['nvim']}; config {summary['config_commit']}; artifacts {directory}",
        flush=True,
    )
    for index, (group, case) in enumerate(cases, 1):
        print(f"[{index}/{len(cases)}] {group}/{case.label()}", flush=True)
        case_directory = (
            directory / f"{index:03d}-{group}-{case.name.replace(':', '-')}"
        )
        try:
            result = execute(case, case_directory)
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
        if log.exists():
            content = log.read_text(errors="replace")
            print(
                content if result["status"] == "pass" else content[-10000:],
                end="",
                flush=True,
            )
        (directory / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    failed = [r for r in summary["results"] if r["status"] == "fail"]
    skipped = [r for r in summary["results"] if r["status"] == "skip"]
    print(
        f"\nChecks: {len(cases) - len(failed) - len(skipped)} passed, {len(failed)} failed, {len(skipped)} skipped."
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
    return bool(failed)


if __name__ == "__main__":
    sys.exit(main())
