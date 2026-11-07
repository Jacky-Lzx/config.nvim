"""Run the resolved file-tools checkout against this configuration's real PTY."""

import json
import os
import runpy
import subprocess
import sys
from pathlib import Path

root = Path(os.environ["NVIM_CONFIG_ROOT"])
directory = Path(os.environ["NVIM_TEST_TMP"])
subprocess.run(
    [
        "nvim",
        "--headless",
        "-u",
        "NONE",
        "-i",
        "NONE",
        "--noplugin",
        "-l",
        str(root / "tests/support/checked.lua"),
        str(root / "tests/integration/environment.lua"),
    ],
    cwd=root,
    check=True,
    timeout=15,
)
entries = json.loads((directory / "environment.json").read_text())
plugin = next(entry for entry in entries if entry["id"] == "file-tools.nvim")
for name in list(os.environ):
    if name.startswith("FILE_TOOLS_"):
        os.environ.pop(name)
os.environ.update(FILE_TOOLS_CONFIGURED="1", FILE_TOOLS_INTEGRATED="1")
variant = sys.argv[1] if len(sys.argv) > 1 else "tree"
if variant in ("dashboard-picker", "dashboard-tree"):
    os.environ["FILE_TOOLS_DASHBOARD_TEST"] = variant.removeprefix("dashboard-")
elif variant != "tree":
    raise ValueError("Unknown file-tools workflow: " + variant)
runpy.run_path(str(Path(plugin["directory"]) / "tests/tui.py"), run_name="__main__")
