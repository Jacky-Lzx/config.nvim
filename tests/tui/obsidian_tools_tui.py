"""Drive native vault workflows through actual terminal keys and rendered UI."""
import errno
import fcntl
import json
import os
from pathlib import Path
import pty
import select
import shutil
import struct
import subprocess
import tempfile
import termios
import time

ROOT = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix="obsidian-tools-tui-") as temporary:
    temp = Path(temporary).resolve()
    vault = temp / "vault"
    for folder in (".obsidian", "notes", "templates"):
        (vault / folder).mkdir(parents=True, exist_ok=True)
    (vault / ".nvim-plugins.lua").write_text("return {{id='obsidian-tools.nvim', opts={workspaces={{name='Fixture',path=vim.env.OBSIDIAN_TEST_VAULT}},daily_notes={template='daily-note.md'}}}}")
    (vault / "notes/alpha.md").write_text('---\nid: alpha\naliases: [Alpha]\ntags: [science]\n---\n# Alpha\n## Heading\nA block ^block-a\n')
    (vault / "notes/beta.md").write_text('# Beta\n\n[[notes/alpha|Alpha]]\nneedle beta text\n')
    (vault / "notes/scratch.md").write_text('')
    (vault / "templates/daily-note.md").write_text('---\nid: template\naliases: ["{{title}}"]\ntags: [daily-notes]\n---\n# {{title}}\nDAILY TEMPLATE {{date}}\n')
    (temp / "outside.md").write_text('# Outside\n')
    shutil.copyfile(ROOT / "plugin-tools-lock.json", temp / "plugins.json")
    result, stage_file = temp / "result", temp / "stage"
    env = dict(os.environ, TERM="xterm-256color", NVIM_CONFIG_ROOT=str(ROOT),
               NVIM_TEST_TMP=str(temp), NVIM_TEST_SCENARIO="writing", NVIM_SMOKE_TEST="1",
               NVIM_TEST_ENABLE_THIRD_PARTY="0", XDG_CACHE_HOME=str(temp / "cache"),
               XDG_STATE_HOME=str(temp / "state"), NVIM_LOG_FILE=str(temp / "nvim.log"),
               NVIM_PLUGIN_LOCKFILE=str(temp / "plugins.json"), OBSIDIAN_TEST_VAULT=str(vault),
               OBSIDIAN_TEST_RESULT=str(result), OBSIDIAN_TEST_STAGE=str(stage_file))
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 38, 140, 0, 0))
    process = subprocess.Popen([
        "nvim", "-n", "-i", "NONE", "--cmd",
        "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/support/setup.lua'); "
        "vim.secure.read=function(path) assert(path==vim.env.OBSIDIAN_TEST_VAULT .. '/.nvim-plugins.lua'); "
        "return table.concat(vim.fn.readfile(path), string.char(10)) end",
        "-u", str(ROOT / "init.lua"), str(vault / "notes/scratch.md"),
        "-c", "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/tui/obsidian_tools_tui.lua')",
    ], cwd=vault, env=env, stdin=slave, stdout=slave, stderr=slave)
    os.close(slave)
    output, handled = bytearray(), set()
    deadline = time.monotonic() + 60
    try:
        while process.poll() is None and time.monotonic() < deadline:
            if select.select([master], [], [], 0.02)[0]:
                try:
                    output.extend(os.read(master, 65536))
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
            stage = stage_file.read_text().splitlines() if stage_file.exists() else []
            if len(stage) == 2 and stage[0] not in handled:
                os.write(master, json.loads(stage[1]).encode())
                handled.add(stage[0])
        if process.poll() is None:
            process.kill()
        process.wait()
        message = result.read_text() if result.exists() else "No result; stages: " + repr(handled)
        assert process.returncode == 0 and message.startswith("PASS"), message + "\n" + output.decode(errors="replace")[-6000:]
        print(message.strip())
    finally:
        if process.poll() is None:
            process.kill()
        process.wait()
        os.close(master)
