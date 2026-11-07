"""Locate grouped test scripts without coupling their paths to suite membership."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GROUPS = ("native", "integration", "tui", "support", "benchmarks")


def test_path(filename):
    matches = [ROOT / "tests" / group / filename for group in GROUPS]
    matches = [path for path in matches if path.is_file()]
    if len(matches) != 1:
        raise ValueError(f"Expected one test script for {filename!r}, found {len(matches)}")
    return matches[0]
