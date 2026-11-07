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
parser.add_argument("--lockfile", type=Path, default=Path(__file__).resolve().parents[2] / "plugin-tools-lock.json")
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
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
    vault = directory / "vault"
    vault.mkdir(exist_ok=True)
    manifest = vault / ".nvim-plugins.lua"
    manifest.write_text('return {{id="obsidian-tools.nvim", opts={workspaces={{path=vim.env.NVIM_REMOTE_VAULT}}}}}\n')
    env["NVIM_REMOTE_VAULT"] = str(vault)
    # Trust only this generated fixture, using the isolated state directory.
    trust = "lua vim.fn.mkdir(vim.fn.stdpath('state'), 'p'); assert(vim.secure.trust({action='allow',path=vim.env.NVIM_REMOTE_VAULT..'/.nvim-plugins.lua'}))"
    subprocess.run(["nvim", "--headless", "-u", "NONE", "-i", "NONE", "--cmd", trust, "-n", "-l",
                    str(root / "scripts/install-plugins.lua")], cwd=vault, env=env, check=True, timeout=360)
    for scenario, filename in (("minimal", None), ("default", None), ("default", "sample.md"), ("writing", "note.md")):
        selected_vault = filename == "note.md"
        project = vault if selected_vault else directory
        if filename:
            (project / filename).write_text("# Remote installation\n\n[[sample]]\n")
        command = ["nvim", "--headless", "-i", "NONE", "-n", "--cmd",
                   "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/support/setup.lua')",
                   "-u", str(root / "init.lua")]
        if filename:
            command.append(str(project / filename))
        command += ["-c", "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/integration/remote_startup.lua')"]
        subprocess.run(command, cwd=project, env=dict(env, NVIM_TEST_SCENARIO=scenario,
                       NVIM_REMOTE_SELECTED_VAULT="1" if selected_vault else "0"), check=True, timeout=45)
    print("PASS: pinned GitHub installation, default/Markdown/vault startup and first-use APIs without development checkouts")
finally:
    if not args.directory:
        shutil.rmtree(directory)
