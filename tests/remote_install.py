"""Install pinned GitHub plugins and start fresh editors with no development checkouts."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--directory", type=Path, help="Keep the isolated installation for inspection")
parser.add_argument("--lockfile", type=Path, default=Path(__file__).resolve().parents[1] / "plugin-tools-lock.json")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
directory = args.directory or Path(tempfile.mkdtemp(prefix="nvim-remote-install-"))
directory = directory.resolve()
directory.mkdir(parents=True, exist_ok=True)
shutil.copyfile(args.lockfile, directory / "plugins.json")
env = dict(os.environ, NVIM_CONFIG_ROOT=str(root), NVIM_TEST_TMP=str(directory),
           NVIM_DEV_PLUGIN_ROOT=str(directory / "missing-development"),
           XDG_DATA_HOME=str(directory / "data"), XDG_STATE_HOME=str(directory / "state"),
           XDG_CACHE_HOME=str(directory / "cache"), NVIM_LOG_FILE=str(directory / "nvim.log"),
           NVIM_PLUGIN_ROOT=str(directory / "packages"), NVIM_PLUGIN_LOCKFILE=str(directory / "plugins.json"),
           NVIM_SMOKE_TEST="1", NVIM_TEST_ENABLE_THIRD_PARTY="0")
env.pop("NVIM_PLUGIN_TOOLS_PATH", None)
for name in ("PROF", "NVIM_TEST_SCENARIO", "NVIM_TEST_LINK_FIRST"):
    env.pop(name, None)
try:
    subprocess.run(["nvim", "--headless", "-u", "NONE", "-i", "NONE", "-n", "-l",
                    str(root / "scripts/install-plugins.lua")], cwd=root, env=env, check=True, timeout=360)
    for scenario in ("minimal", "default"):
        subprocess.run(["nvim", "--headless", "-i", "NONE", "-n", "--cmd",
                        "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')",
                        "-u", str(root / "init.lua"), "-c",
                        "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/remote_startup.lua')"],
                       cwd=root, env=dict(env, NVIM_TEST_SCENARIO=scenario), check=True, timeout=45)
    print("PASS: pinned GitHub installation, minimal/default startup and first-use APIs without development checkouts")
finally:
    if not args.directory:
        shutil.rmtree(directory)
