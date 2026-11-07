"""Resolve test dependencies through the configuration's actual package graph."""

import json
import subprocess


def resolved_plugins(root, directory):
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
    return {
        entry["id"]: entry
        for entry in json.loads((directory / "environment.json").read_text())
    }
