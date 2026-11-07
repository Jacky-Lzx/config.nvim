"""Validate executable registrations and explicit support/manual script roles."""

import json


def validate_registry(root, suites):
    roles = json.loads((root / "tests/roles.json").read_text())
    registered, labels = set(), set()
    for suite, cases in suites.items():
        for case in cases:
            label = suite + "/" + case.label()
            if label in labels:
                raise ValueError("Duplicate case: " + label)
            labels.add(label)
            if not case.files:
                raise ValueError("Missing script registration: " + label)
            for name in case.files:
                if not (root / name).is_file():
                    raise ValueError("Missing registered script: " + name)
                registered.add(name)
    for category in ("support", "manual"):
        for name, reason in roles[category].items():
            if not reason.strip() or not (root / name).is_file():
                raise ValueError("Missing script or role description: " + name)
            if name in registered:
                raise ValueError("Script has conflicting roles: " + name)
            registered.add(name)
    present = {
        path.relative_to(root).as_posix()
        for path in (root / "tests").rglob("*")
        if path.is_file()
        and path.suffix in (".lua", ".py", ".sh")
        and "__pycache__" not in path.parts
    }
    present.discard("tests/run.py")
    missing = sorted(present - registered)
    if missing:
        raise ValueError("Unregistered test scripts: " + ", ".join(missing))
