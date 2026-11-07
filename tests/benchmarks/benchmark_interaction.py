"""Fresh real-PTY startup and first-input measurements; no external LSP or AI servers."""

import argparse
import errno
import fcntl
import json
import os
from pathlib import Path
import pty
import re
import select
import statistics
import struct
import subprocess
import tempfile
import termios
import time

parser = argparse.ArgumentParser()
parser.add_argument("--samples", type=int, default=5)
parser.add_argument("--output", type=Path, required=True)
parser.add_argument("--directory", type=Path)
parser.add_argument(
    "--baseline",
    type=Path,
    help="JSON map of module names to old source snapshots; interleave with current config",
)
args = parser.parse_args()
assert args.samples > 0
root = Path(__file__).resolve().parents[2]
directory = (
    args.directory or Path(tempfile.mkdtemp(prefix="nvim-interaction-bench-"))
).resolve()
directory.mkdir(parents=True, exist_ok=True)
project = directory / "project"
project.mkdir(exist_ok=True)
for name, text in {
    "sample.lua": "local value = 1\n",
    "sample.py": "value = 1\n",
    "sample.tex": "\\documentclass{article}\n\\begin{document}\n$x + \\alpha$\n\\end{document}\n",
}.items():
    (project / name).write_text(text)
scenarios = {
    "empty": ("minimal", None),
    "lua": ("lua", "sample.lua"),
    "python": ("python", "sample.py"),
    "latex": ("writing", "sample.tex"),
}
actions = {"insert": b"i", "command": b":", "picker": b" sf"}
records = []
variants = {"current": {}}
if args.baseline:
    variants = {"baseline": json.loads(args.baseline.read_text()), **variants}
for index in range(args.samples + 1):
    # Each action gets a fresh process, so a command line cannot warm completion
    # before the insert measurement. Alternate traversal order to reduce drift.
    cases = [(s, a, v) for s in scenarios for a in actions for v in variants]
    if index % 2:
        cases.reverse()
    for scenario, action, variant in cases:
        fixture = directory / f"{index}-{scenario}-{action}-{variant}"
        # Reject reused trials rather than observing a stale readiness snapshot.
        fixture.mkdir()
        result, profile = fixture / "result.json", fixture / "startup.log"
        (fixture / "plugins.json").write_bytes(
            (root / "plugin-tools-lock.json").read_bytes()
        )
        env = dict(
            os.environ,
            TERM="xterm-256color",
            NVIM_CONFIG_ROOT=str(root),
            NVIM_TEST_TMP=str(fixture),
            NVIM_TEST_SCENARIO=scenarios[scenario][0],
            NVIM_SMOKE_TEST="1",
            NVIM_TEST_ENABLE_THIRD_PARTY="0",
            XDG_STATE_HOME=str(fixture / "state"),
            XDG_CACHE_HOME=str(fixture / "cache"),
            NVIM_LOG_FILE=str(fixture / "nvim.log"),
            NVIM_PLUGIN_LOCKFILE=str(fixture / "plugins.json"),
            NVIM_BENCH_RESULT=str(result),
            NVIM_BENCH_ACTION=action,
        )
        env.pop("PROF", None)
        env.pop("NVIM_TEST_LINK_FIRST", None)
        command = ["nvim", "-n", "-i", "NONE", "--startuptime", str(profile)]
        if variants[variant]:
            env["NVIM_BENCH_MODULES"] = json.dumps(variants[variant])
            command += [
                "--cmd",
                "lua for name,path in pairs(vim.json.decode(vim.env.NVIM_BENCH_MODULES)) do package.preload[name]=function() return dofile(path) end end",
            ]
        command += [
            "--cmd",
            "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/support/setup.lua')",
            "-u",
            str(root / "init.lua"),
            "-c",
            "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/benchmarks/benchmark_interaction.lua')",
        ]
        if scenarios[scenario][1]:
            command.append(str(project / scenarios[scenario][1]))
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 120, 0, 0))
        started = time.perf_counter_ns()
        child = subprocess.Popen(
            command, cwd=project, env=env, stdin=slave, stdout=slave, stderr=slave
        )
        os.close(slave)
        output, pending, sent, measured, record = bytearray(), b"", None, None, None
        deadline = time.monotonic() + 25
        try:
            while child.poll() is None and time.monotonic() < deadline:
                if select.select([master], [], [], 0.001)[0]:
                    try:
                        chunk = os.read(master, 65536)
                        output.extend(chunk)
                        pending += chunk
                        while True:
                            query = re.search(
                                rb"\x1b\[(?:5|6)n|\x1b\]11;\?(?:\x07|\x1b\\)", pending
                            )
                            if not query:
                                pending = pending[-64:]
                                break
                            response = {
                                b"\x1b[5n": b"\x1b[0n",
                                b"\x1b[6n": b"\x1b[1;1R",
                            }.get(query[0], b"\x1b]11;rgb:0000/0000/0000\x1b\\")
                            os.write(master, response)
                            pending = pending[query.end() :]
                    except OSError as error:
                        if error.errno != errno.EIO:
                            raise
                if result.exists():
                    state = json.loads(result.read_text())
                    assert state["phase"] != "error", state.get("error")
                    if state["phase"] == "startup" and sent is None:
                        startup = state
                        sent = time.perf_counter_ns()
                        startup_wall = (sent - started) / 1e6
                        # The empty startup opens the configured dashboard; its New File
                        # action is the actual route into the first editable Insert mode.
                        keys = (
                            b"n"
                            if scenario == "empty" and action == "insert"
                            else actions[action]
                        )
                        os.write(master, keys)
                    elif state["phase"] == "action" and measured is None:
                        measured = (time.perf_counter_ns() - sent) / 1e6
                        record = dict(
                            state,
                            scenario=scenario,
                            action=action,
                            variant=variant,
                            input_to_ready_ms=measured,
                            process_to_ready_ms=startup_wall,
                            startup=startup,
                        )
            try:
                child.wait(timeout=max(0.1, deadline - time.monotonic()))
            except subprocess.TimeoutExpired:
                (fixture / "terminal.log").write_bytes(output)
                raise AssertionError(
                    "PTY timed out: " + output.decode(errors="replace")[-5000:]
                )
            assert child.returncode == 0 and measured is not None, output.decode(
                errors="replace"
            )[-2500:]
            # Neovim logs both the thin TUI client and the editor process. Use
            # the editor's final marker rather than the client's early startup.
            markers = re.findall(
                r"^\s*([\d.]+).*NVIM STARTED", profile.read_text(), re.MULTILINE
            )
            assert markers, profile.read_text()
            record["native_startup_ms"] = float(markers[-1])
            (fixture / "measurement.json").write_text(
                json.dumps(record, indent=2) + "\n"
            )
            if index:
                records.append(record)
        finally:
            if child.poll() is None:
                child.kill()
            child.wait()
            os.close(master)
summary = {}
for variant in variants:
    summary[variant] = {}
    for scenario in scenarios:
        rows = [
            r for r in records if r["scenario"] == scenario and r["variant"] == variant
        ]
        summary[variant][scenario] = {
            "startup_median_ms": statistics.median(
                r["native_startup_ms"] for r in rows
            ),
            "resolve_median_ms": statistics.median(r["resolve_ms"] for r in rows),
            "register_median_ms": statistics.median(r["register_ms"] for r in rows),
            "first_input_median_ms": {
                a: statistics.median(
                    r["input_to_ready_ms"] for r in rows if r["action"] == a
                )
                for a in actions
            },
        }
report = {
    "conditions": "fresh real 120x40 PTYs; warm OS caches; isolated state/cache/lock; mocked LSP; AI disabled; each action starts cold",
    "samples_per_action": args.samples,
    "variants": variants,
    "summary": summary,
    "records": records,
}
args.output.write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(summary, indent=2))
