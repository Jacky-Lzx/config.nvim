"""Keep nested PTY fixtures, transcripts and progress in the case artifact tree."""

from contextlib import contextmanager
import json
import os
from pathlib import Path
import re
import shutil
import tempfile
import time


def artifact_root():
    value = os.environ.get("NVIM_TEST_ARTIFACT_DIR") or os.environ.get("NVIM_TEST_TMP")
    if not value:
        value = tempfile.mkdtemp(prefix="nvim-test-evidence-")
        os.environ["NVIM_TEST_ARTIFACT_DIR"] = value
    path = Path(value)
    path.mkdir(parents=True, exist_ok=True)
    return path


@contextmanager
def workspace(prefix="fixture-", dir=None):
    parent = os.environ.get("NVIM_TEST_ARTIFACT_DIR") or os.environ.get("NVIM_TEST_TMP")
    path = Path(tempfile.mkdtemp(prefix=prefix, dir=parent or dir)).resolve()
    previous = os.environ.get("NVIM_TEST_ARTIFACT_DIR")
    os.environ["NVIM_TEST_ARTIFACT_DIR"] = str(path)
    try:
        yield str(path)
    except BaseException:
        print("PTY evidence retained: " + str(path), flush=True)
        raise
    else:
        if not parent:
            shutil.rmtree(path)
    finally:
        if previous is None:
            os.environ.pop("NVIM_TEST_ARTIFACT_DIR", None)
        else:
            os.environ["NVIM_TEST_ARTIFACT_DIR"] = previous


def record_stage(label):
    path = artifact_root() / "stage.json"
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps({"stage": label, "time": time.time()}) + "\n")
    temporary.replace(path)


class Transcript(bytearray):
    def __init__(self):
        super().__init__()
        root = artifact_root()
        index = 1
        self.path = root / "terminal.bin"
        while self.path.exists():
            index += 1
            self.path = root / f"terminal-{index}.bin"
        self.path.touch()

    def extend(self, data):
        super().extend(data)
        with self.path.open("ab") as output:
            output.write(data)
        text = re.sub(
            rb"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1b\\)|[()#][0-9A-Z]|[@-_])",
            b"",
            bytes(self)[-16000:],
        )
        self.path.with_suffix(".txt").write_text(text.decode(errors="replace"))
