"""Track owned process groups and clean up descendants across PTY sessions."""

import json
import os
from pathlib import Path
import signal
import subprocess
import threading

LEDGER = "NVIM_TEST_PROCESS_LEDGER"
_active = {}
_lock = threading.RLock()
_cancelled = False


def spawn(*args, **kwargs):
    with _lock:
        if _cancelled:
            raise InterruptedError("Test run cancelled")
        return _spawn(*args, **kwargs)


def _spawn(*args, **kwargs):
    kwargs.setdefault("start_new_session", True)
    process = subprocess.Popen(*args, **kwargs)
    ledger = kwargs.get("env", os.environ).get(LEDGER)
    if ledger:
        entry = (
            json.dumps(
                {
                    "pid": process.pid,
                    "parent": os.getpid(),
                    "group": os.getpgid(process.pid),
                }
            )
            + "\n"
        )
        with open(ledger, "a") as output:
            output.write(entry)
    _active[process.pid] = (process, ledger)
    return process


def release(process):
    with _lock:
        _active.pop(process.pid, None)


def reset_cancellation():
    global _cancelled
    with _lock:
        _cancelled = False


def cancel_all():
    global _cancelled
    with _lock:
        _cancelled = True
        owned = list(_active.values())
    for process, ledger in owned:
        stop(process, ledger)


def stop(process, ledger=None):
    rows = []
    ledger = ledger or os.environ.get(LEDGER)
    if ledger and Path(ledger).exists():
        for line in Path(ledger).read_text().splitlines():
            try:
                item = json.loads(line)
                rows.append((item["pid"], item["parent"], item["group"]))
            except (ValueError, KeyError):
                continue
    try:
        listing = subprocess.run(
            ["ps", "-axo", "pid=,ppid=,pgid="],
            capture_output=True,
            text=True,
            timeout=3,
        )
        rows.extend(
            tuple(map(int, line.split())) for line in listing.stdout.splitlines()
        )
    except (OSError, ValueError, subprocess.SubprocessError):
        pass
    owned = {process.pid}
    while True:
        children = {pid for pid, parent, _ in rows if parent in owned}
        if children <= owned:
            break
        owned.update(children)
    groups = {process.pid} | {group for pid, _, group in rows if pid in owned}
    for group in groups - {os.getpgrp()}:
        try:
            os.killpg(group, signal.SIGKILL)
        except ProcessLookupError:
            pass
    process.wait()
    release(process)
