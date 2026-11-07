"""Run the resolved file-tools checkout against this configuration's real PTY."""

import json
import os
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from support.plugins import resolved_plugins

root = Path(os.environ["NVIM_CONFIG_ROOT"])
directory = Path(os.environ["NVIM_TEST_TMP"])
plugin = resolved_plugins(root, directory)["file-tools.nvim"]
for name in list(os.environ):
    if name.startswith("FILE_TOOLS_"):
        os.environ.pop(name)
os.environ.update(
    FILE_TOOLS_CONFIGURED="1",
    FILE_TOOLS_INTEGRATED="1",
    FILE_TOOLS_CONFIG_INIT=str(root / "init.lua"),
    FILE_TOOLS_CONFIG_SETUP=str(root / "tests/support/setup.lua"),
    FILE_TOOLS_TEST_ADAPTER=str(root / "tests/support/file_tools.lua"),
)
variant = sys.argv[1] if len(sys.argv) > 1 else "tree"
if variant in ("dashboard-picker", "dashboard-tree"):
    os.environ["FILE_TOOLS_DASHBOARD_TEST"] = variant.removeprefix("dashboard-")
elif variant != "tree":
    raise ValueError("Unknown file-tools workflow: " + variant)
runpy.run_path(str(Path(plugin["directory"]) / "tests/tui.py"), run_name="__main__")
