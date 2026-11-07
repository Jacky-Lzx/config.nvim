"""Read one complete, unhandled input stage from a caller-owned scenario."""

import json


def event(stage, directory, handled):
    if stage is None:
        return None
    path = directory / stage.file
    if not path.exists():
        return None
    lines = path.read_text().splitlines()
    if not lines or lines[0] in handled:
        return None
    name = lines[0]
    columns = None
    try:
        if stage.input_file:
            data = (directory / stage.input_file).read_bytes()
        elif len(lines) == 2:
            value = json.loads(lines[1])
            if stage.vim_keys:
                value = value.replace("<CR>", "\r")
            data = value.encode()
        else:
            data = stage.actions.get(name)
    except (FileNotFoundError, json.JSONDecodeError):
        return None
    if data is None:
        return None
    if stage.resize_file:
        resize = directory / stage.resize_file
        if resize.exists():
            columns = int(resize.read_text())
            resize.unlink()
    return name, data, columns
