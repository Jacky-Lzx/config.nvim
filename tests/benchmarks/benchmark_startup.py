"""Fresh-process configured startup; no external LSP or clipboard side effects."""
import argparse
import json
import os
from pathlib import Path
import re
import statistics
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser()
parser.add_argument("--samples", type=int, default=10)
parser.add_argument("--output", type=Path)
args = parser.parse_args()
assert args.samples > 0
root = Path(__file__).resolve().parents[2]
records = []
with tempfile.TemporaryDirectory(prefix="nvim-plugin-tools-benchmark-") as directory:
    temp = Path(directory)
    env = dict(os.environ, NVIM_CONFIG_ROOT=str(root), NVIM_TEST_TMP=directory,
               NVIM_SMOKE_TEST="1", NVIM_TEST_SCENARIO="default", NVIM_LOG_FILE=str(temp / "nvim.log"),
               XDG_CACHE_HOME=str(temp / "cache"), XDG_STATE_HOME=str(temp / "state"))
    env.pop("PROF", None)
    probe = """lua vim.api.nvim_create_autocmd('User', {pattern='ConfigReady', once=true, callback=function()
      assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, '\\n'))
      local m = require('config.plugins').manager
      local c = package.loaded.completion_tools
      local snapshot = {resolve_ms=m.timings.resolve_ms, register_ms=m.timings.start_ms,
        plugins=#m.graph.order, completion=c and c.get_status().configured or false,
        snippets=package.loaded.snippet_tools~=nil, images=package.loaded.image_tools~=nil}
      vim.fn.writefile({vim.json.encode(snapshot)}, vim.env.NVIM_BENCH_SNAPSHOT)
      vim.defer_fn(function() vim.cmd('qa!') end, 0)
    end})"""
    for index in range(args.samples + 1):
        profile, snapshot = temp / f"{index}.time", temp / f"{index}.json"
        env["NVIM_BENCH_SNAPSHOT"] = str(snapshot)
        started = time.monotonic()
        subprocess.run(["nvim", "--headless", "-i", "NONE", "--startuptime", str(profile),
                        "--cmd", "lua dofile(vim.env.NVIM_CONFIG_ROOT..'/tests/support/setup.lua')",
                        "-u", str(root / "init.lua"), "-c", probe],
                       cwd=root, env=env, check=True, capture_output=True, text=True, timeout=30)
        record = json.loads(snapshot.read_text())
        assert not record["completion"] and not record["snippets"] and not record["images"], record
        marker = re.search(r"^\s*([\d.]+).*NVIM STARTED", profile.read_text(), re.MULTILINE)
        assert marker, profile.read_text()
        record["native_startup_ms"] = float(marker[1])
        record["process_wall_ms"] = (time.monotonic() - started) * 1000
        if index:
            records.append(record)
result = {"samples": args.samples, "plugins": records[0]["plugins"],
          "conditions": "fresh headless processes, warm OS/Lua caches; mocked external LSP and clipboard",
          "deferred_engines_remained_cold": True}
for metric in ("native_startup_ms", "resolve_ms", "register_ms", "process_wall_ms"):
    values = sorted(record[metric] for record in records)
    result[metric] = {"median": statistics.median(values), "max": max(values)}
output = json.dumps(result, indent=2) + "\n"
if args.output:
    args.output.write_text(output)
print(output, end="")
