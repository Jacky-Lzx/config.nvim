"""Measure real TeX LSP completion, PTY burst input, save and diagnostic refresh.

Generated multi-file projects keep the workload reproducible and user files intact.
Every trial retains versions, source revisions, raw measurements and terminal output.
"""

import argparse
import errno
import fcntl
import json
import math
import os
import pty
import select
import shutil
import signal
import statistics
import struct
import subprocess
import termios
import time
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, required=True)
    parser.add_argument("--rounds", type=int, default=10)
    parser.add_argument("--sections", type=int, default=500)
    parser.add_argument(
        "--project",
        type=Path,
        help="Copy an existing TeX project into the isolated trial",
    )
    parser.add_argument(
        "--document", default="main.tex", help="Document relative to --project"
    )
    parser.add_argument(
        "--baseline", type=Path, help="Compare old module snapshots with current policy"
    )
    args = parser.parse_args()
    assert args.rounds > 0 and args.sections > 0
    root = Path(__file__).resolve().parents[1]
    directory = args.directory.resolve()
    if args.project:
        source = args.project.resolve()
        if source == directory or source in directory.parents:
            parser.error("The output directory must be outside the source project")
    directory.mkdir(parents=True, exist_ok=False)
    variants = {"current": {}}
    if args.baseline:
        variants = {"baseline": json.loads(args.baseline.read_text()), **variants}
    report = {
        "conditions": "real 120x40 PTY; real texquill; AI and grammar server disabled; build-on-save disabled; generated multi-file TeX",
        "rounds": args.rounds,
        "sections": args.sections,
        "source_project": str(args.project.resolve()) if args.project else None,
        "config": subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=root, text=True
        ).strip(),
        "nvim": subprocess.check_output(["nvim", "--version"], text=True).splitlines()[
            0
        ],
        "texquill": subprocess.check_output(
            ["texquill", "--version"], text=True
        ).strip(),
        "records": [],
        "summary": {},
    }
    (directory / "config.diff").write_bytes(
        subprocess.check_output(["git", "diff"], cwd=root)
    )
    (directory / "plugin-lock.json").write_bytes(
        (root / "plugin-tools-lock.json").read_bytes()
    )
    report["plugins"] = {}
    plugin_root = Path(
        os.environ.get(
            "NVIM_DEV_PLUGIN_ROOT", str(Path.home() / "Documents/Github/nvim_plugins")
        )
    )
    for path in sorted(plugin_root.glob("*.nvim")):
        if (path / ".git").exists():
            report["plugins"][path.name] = {
                "head": subprocess.check_output(
                    ["git", "rev-parse", "HEAD"], cwd=path, text=True
                ).strip(),
                "dirty": bool(
                    subprocess.check_output(["git", "status", "--porcelain"], cwd=path)
                ),
            }
    sources = directory / "sources"
    sources.mkdir()
    for name in ("benchmark_workflows.py", "benchmark_workflows.lua"):
        shutil.copyfile(root / "tests" / name, sources / name)
    for variant, modules in variants.items():
        trial = directory / variant
        trial.mkdir()
        for name, source in list(modules.items()):
            snapshot = trial / (name + ".lua")
            shutil.copyfile(source, snapshot)
            modules[name] = str(snapshot)
        project = trial / "project"
        if args.project:
            source = args.project.resolve()
            (source / args.document).resolve().relative_to(source)
            shutil.copytree(
                source,
                project,
                symlinks=True,
                ignore=shutil.ignore_patterns(
                    ".git",
                    ".venv",
                    "node_modules",
                    "build",
                    "output",
                    "__pycache__",
                    ".nvim-plugins.lua",
                ),
            )
            document = project / args.document
            document.resolve().relative_to(project)
            raw = document.read_text()
            assert r"\begin{document}" in raw and r"\end{document}" in raw, (
                "Choose a complete TeX document"
            )
            raw = raw.replace(
                r"\begin{document}",
                "\\begin{document}\n% NVIM_WORKFLOW_PROBE\n\\ref{}\nBenchmark text.\n\\label{section:nvimbenchmark}\n",
                1,
            )
            document.write_text(raw)
        else:
            project.mkdir()
            document = project / "main.tex"
            lines = [
                r"\documentclass{article}",
                r"\begin{document}",
                "% Real LSP workload",
                "% NVIM_WORKFLOW_PROBE",
                r"\ref{}",
                "Benchmark text.",
            ]
            for section in range(args.sections):
                lines += [
                    rf"\section{{Section {section}}}\label{{section:{section:04d}}}",
                    "A reproducible paragraph with $x^2 + y^2 = z^2$ and text.",
                ]
            for chapter in range(5):
                (project / f"chapter{chapter}.tex").write_text(
                    "\n".join(lines[6 : 6 + args.sections * 2]).replace(
                        "section:", f"chapter{chapter}:"
                    )
                    + "\n"
                )
                lines.append(rf"\input{{chapter{chapter}}}")
            lines.append(r"\end{document}")
            document.write_text("\n".join(lines) + "\n")
        (project / ".texquill.json").write_text("{}\n")
        result = trial / "state.json"
        env = dict(
            os.environ,
            TERM="xterm-256color",
            NVIM_CONFIG_ROOT=str(root),
            NVIM_TEST_TMP=str(trial),
            NVIM_TEST_SCENARIO="writing",
            NVIM_SMOKE_TEST="1",
            NVIM_TEST_ENABLE_THIRD_PARTY="0",
            XDG_STATE_HOME=str(trial / "state"),
            XDG_CACHE_HOME=str(trial / "cache"),
            NVIM_LOG_FILE=str(trial / "nvim.log"),
            NVIM_PLUGIN_LOCKFILE=str(directory / "plugin-lock.json"),
            NVIM_WORKFLOW_RESULT=str(result),
            NVIM_WORKFLOW_ROUNDS=str(args.rounds),
            NVIM_BENCH_MODULES=json.dumps(modules),
        )
        prepare = """lua
for name,path in pairs(vim.json.decode(vim.env.NVIM_BENCH_MODULES)) do package.preload[name]=function() return dofile(path) end end
dofile(vim.env.NVIM_CONFIG_ROOT..'/tests/setup.lua')
vim.lsp.start = _G.config_test_real_lsp_start
local enable = vim.lsp.enable
vim.lsp.enable = function(names, enabled)
  for _, name in ipairs(type(names)=='table' and names or {names}) do if name=='texquill' then enable(name, enabled) end end
end
vim.lsp.config('texquill', {settings={latex={build={onSave=false},diagnostics={chktex={enabled=false}}}},init_options={build={onSave=false},diagnostics={chktex={enabled=false}}}})
dofile(vim.env.NVIM_CONFIG_ROOT..'/tests/benchmark_workflows.lua')
"""
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 120, 0, 0))
        child = subprocess.Popen(
            [
                "nvim",
                "-n",
                "-i",
                "NONE",
                "--cmd",
                prepare,
                "-u",
                str(root / "init.lua"),
                str(document),
            ],
            cwd=project,
            env=env,
            stdin=slave,
            stdout=slave,
            stderr=slave,
            start_new_session=True,
        )
        os.close(slave)
        output, sent, completed = bytearray(), {}, set()
        deadline = time.monotonic() + 90 + args.rounds * 15
        state = {}
        try:
            while child.poll() is None and time.monotonic() < deadline:
                if select.select([master], [], [], 0.002)[0]:
                    try:
                        chunk = os.read(master, 65536)
                        output.extend(chunk)
                        if b"\x1b[6n" in chunk:
                            os.write(master, b"\x1b[1;1R")
                        if b"\x1b]11;?" in chunk:
                            os.write(master, b"\x1b]11;rgb:0000/0000/0000\x1b\\")
                    except OSError as error:
                        if error.errno != errno.EIO:
                            raise
                if not result.exists():
                    continue
                state = json.loads(result.read_text())
                if state["phase"] == "input" and state["step"] not in sent:
                    sent[state["step"]] = time.monotonic_ns()
                    os.write(master, state["keys"].encode())
                elif state["phase"] == "completed" and state["step"] not in completed:
                    record = dict(state["records"][-1], variant=variant)
                    record["elapsed_ms"] = (
                        time.monotonic_ns() - sent[state["step"]]
                    ) / 1e6
                    report["records"].append(record)
                    completed.add(state["step"])
                    (trial / "state.json.ack").touch()
                elif state["phase"] == "error":
                    raise AssertionError(state)
                # Keep draining the terminal after 'done': exit redraws can fill
                # the PTY and block Neovim if the parent waits without reading.
            assert state.get("phase") == "done", state
            child.wait(timeout=10)
            assert child.returncode == 0 and state.get("phase") == "done", state
            report["records"] += [
                dict(row, variant=variant)
                for row in state["records"]
                if row["action"] == "diagnostic_refresh"
            ]
            report.setdefault("workloads", {})[variant] = {
                key: state[key] for key in ("client", "lines", "bytes")
            }
        finally:
            if child.poll() is None:
                os.killpg(child.pid, signal.SIGTERM)
            child.wait()
            os.close(master)
            (trial / "terminal.log").write_bytes(output)
            (directory / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    for variant in variants:
        summary = report["summary"][variant] = {}
        for action in ("completion", "burst", "save", "diagnostic_refresh"):
            values = sorted(
                row["elapsed_ms"]
                for row in report["records"]
                if row["variant"] == variant and row["action"] == action
            )
            summary[action] = {
                "first_ms": next(
                    row["elapsed_ms"]
                    for row in report["records"]
                    if row["variant"] == variant and row["action"] == action
                ),
                "median_ms": statistics.median(values),
                "p95_ms": values[math.ceil(0.95 * len(values)) - 1],
                "max_ms": max(values),
            }
    (directory / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report["summary"], indent=2))


if __name__ == "__main__":
    main()
