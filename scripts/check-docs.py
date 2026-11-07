"""Validate documentation without downloads or writes to the checkout.

The canonical copy lives in plugin-tools.nvim/tests/docs_checks.py. Sibling
plugins vendor it with scripts/sync-test-runner.py. Configuration runs it locally.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
HEADINGS = ("Features", "Requirements", "Installation", "Usage", "Documentation", "Development")
LINK = re.compile(r'!?\[[^\]\n]*\]\((<?[^\s)]+>?)(?:\s+["\'][^\n]*["\'])?\)')
TAG = re.compile(r'(?<!\S)\*([^*\s]+)\*(?=\s|$)')


def heading_ids(text):
    result, counts, code = set(), {}, False
    for line in text.splitlines():
        if line.startswith("```"):
            code = not code
        if code or not line.startswith("#"):
            continue
        title = re.sub(r"^#+\s*", "", line)
        title = re.sub(r"\[([^]]+)\]\([^)]+\)", r"\1", title)
        title = re.sub(r"[^\w\- ]", "", title.lower()).replace(" ", "-")
        count = counts.get(title, 0)
        counts[title] = count + 1
        result.add(title + ("-" + str(count) if count else ""))
    result.update(re.findall(r'<a\s+(?:id|name)=["\']([^"\']+)', text))
    return result


def markdown_errors(root):
    errors = []
    files = [root / "README.md"]
    files.extend(root / relative for relative in ("tests/README.md", "examples/README.md", "lua/snippet_collections/README.md") if (root / relative).is_file())
    for directory in ("doc", "docs"):
        files.extend(sorted((root / directory).rglob("*.md")))
    for path in files:
        if not path.is_file():
            errors.append(str(path.relative_to(root)) + ": missing file")
            continue
        text = path.read_text()
        # Inline code and fenced examples can intentionally contain fake links.
        searchable = re.sub(r"```[^\n]*\n.*?^```[^\n]*$", "", text, flags=re.M | re.S)
        searchable = re.sub(r"`[^`\n]+`", "", searchable)
        for match in LINK.finditer(searchable):
            url = match[1].strip("<>")
            if urlsplit(url).scheme or url.startswith("//"):
                continue
            parsed = urlsplit(url)
            target = (path.parent / unquote(parsed.path)).resolve() if parsed.path else path
            label = str(path.relative_to(root)) + ": " + url
            if not target.exists():
                errors.append(label + " (missing target)")
            elif parsed.fragment and target.suffix == ".md" and unquote(parsed.fragment) not in heading_ids(target.read_text()):
                errors.append(label + " (missing heading)")
    return errors


def help_errors(root, prefix):
    errors, tags = [], {}
    files = sorted((root / "doc").glob("*.txt"))
    for path in files:
        text = path.read_text()
        if not text.startswith("*" + path.name + "*\t"):
            errors.append(str(path.relative_to(root)) + ": expected filename tag and tab on first line")
        if "vim:tw=78:ts=8:noet:ft=help:norl:" not in text:
            errors.append(str(path.relative_to(root)) + ": missing help modeline")
        for number, line in enumerate(text.splitlines(), 1):
            for match in TAG.finditer(line):
                tag = match[1]
                if tag in tags:
                    errors.append(f"{path.name}:{number}: duplicate tag {tag}")
                tags[tag] = path.name
    for suffix in ("", "-quickstart", "-commands", "-options", "-api", "-lifecycle", "-troubleshooting"):
        if prefix + suffix not in tags:
            errors.append("Missing help entry: " + prefix + suffix)
    for path in files:
        for tag in re.findall(r"\|([^|\s]+)\|", path.read_text()):
            if (tag == prefix or tag.startswith(prefix + "-")) and tag not in tags:
                errors.append(path.name + ": unresolved local help link " + tag)
    return errors, files


PROBE = r'''
local api = vim.api
local blocks = vim.json.decode(vim.env.NVIM_DOC_BLOCKS)
for index, block in ipairs(blocks) do
  local chunk, err = loadstring(block, "README Lua block " .. index)
  if not chunk then chunk, err = loadstring("return " .. block, "README Lua spec " .. index) end
  assert(chunk, err)
end
local prefix = vim.env.NVIM_DOC_PREFIX or ""
if prefix ~= "" then
  vim.opt.runtimepath:prepend(vim.env.NVIM_DOC_HELP_ROOT)
  vim.cmd.helptags(vim.env.NVIM_DOC_HELP_ROOT .. "/doc")
  for _, suffix in ipairs({ "", "-quickstart", "-commands", "-options", "-api", "-lifecycle", "-troubleshooting" }) do
    vim.cmd.help(prefix .. suffix)
    assert(vim.bo.buftype == "help", "Help entry did not open: " .. prefix .. suffix)
    assert(api.nvim_get_current_line():find("*" .. prefix .. suffix .. "*", 1, true), "Help jumped to another tag")
    assert(api.nvim_buf_get_name(0):find(vim.env.NVIM_DOC_HELP_ROOT, 1, true), "Help opened another plugin")
    vim.cmd("helpclose")
  end
  vim.opt.runtimepath:prepend(vim.env.NVIM_DOC_ROOT)
  for _, path in ipairs(vim.json.decode(vim.env.NVIM_DOC_FIXTURES)) do
    vim.opt.runtimepath:append(path)
  end
  -- Give setup a normal source buffer, not the help buffer used for tag checks.
  vim.cmd.enew()
  local setup = assert(loadstring(vim.env.NVIM_DOC_SETUP, "README native setup"))
  setup()
  -- Commands registered through native plugin scripts are part of installation.
  vim.cmd("runtime! plugin/**/*.lua")
end
vim.cmd("qa!")
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--nvim", default=os.environ.get("NVIM_BIN", "nvim"))
    args = parser.parse_args()
    readme = (ROOT / "README.md").read_text()
    errors = markdown_errors(ROOT)
    for heading in HEADINGS:
        if "\n## " + heading + "\n" not in readme:
            errors.append("README.md: missing heading " + heading)
    if re.search(r"/Users/|~/Documents/Github/|[\u4e00-\u9fff]", readme):
        errors.append("README.md: use English prose and portable public installation examples")
    title = readme.splitlines()[0].removeprefix("# ")
    plugin = title.endswith(".nvim")
    prefix = title.removesuffix(".nvim") if plugin else ""
    files = []
    if plugin:
        issues, files = help_errors(ROOT, prefix)
        errors.extend(issues)
    blocks = re.findall(r"^```lua\s*\n(.*?)^```", readme, re.M | re.S)
    setup = next((b for b in blocks if re.match(r'\s*require\(["\'][^"\']+["\']\)\.setup\(', b)), "")
    if plugin and not setup:
        errors.append("README.md: missing standalone native setup example")
    if errors:
        raise SystemExit("\n".join(errors))
    fixtures = []
    manifest = ROOT / "tests/cases.json"
    if manifest.exists():
        for value in json.loads(manifest.read_text()).get("defaults", {}).values():
            path = Path(os.path.expandvars(value.replace("{root}", str(ROOT)))).expanduser()
            if (path / "lua").is_dir():
                fixtures.append(str(path.resolve()))
    with tempfile.TemporaryDirectory(prefix="nvim-docs-") as temp:
        directory = Path(temp)
        (directory / "doc").mkdir()
        for path in files:
            (directory / "doc" / path.name).write_bytes(path.read_bytes())
        probe = directory / "probe.lua"
        probe.write_text(PROBE)
        env = dict(os.environ, NVIM_DOC_ROOT=str(ROOT), NVIM_DOC_PREFIX=prefix,
                   NVIM_DOC_BLOCKS=json.dumps(blocks), NVIM_DOC_SETUP=setup,
                   NVIM_DOC_FIXTURES=json.dumps(fixtures), NVIM_DOC_HELP_ROOT=temp,
                   XDG_STATE_HOME=str(directory / "state"), XDG_DATA_HOME=str(directory / "data"),
                   XDG_CACHE_HOME=str(directory / "cache"), NVIM_LOG_FILE=str(directory / "nvim.log"))
        subprocess.run([args.nvim, "--headless", "-u", "NONE", "-i", "NONE", "--noplugin", "-n", "-l", str(probe)],
                       cwd=directory, env=env, check=True, timeout=30)
    print("PASS documentation: Markdown targets/headings, README examples, help tags/entries and isolated native setup")


if __name__ == "__main__":
    main()
