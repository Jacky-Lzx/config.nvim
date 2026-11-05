# Snippet migration baseline

`snippets-legacy.json` was exported from the LuaSnip definitions at configuration
commit `21acb6e`, before removing that engine. It is a frozen comparison fixture,
not an executable collection and not generated from the replacement definitions.

The export covers all 154 definitions: global (8), Lua (11), Python (14), Rust (1),
Typst (2), Verilog (8), Markdown (18) and TeX (92). It records trigger, automatic
expansion, postfix, priority, word boundary, description and literal default text.

The export used `example.v`, commentstring `-- %s`, the fixed date `2026.11.05` and
fixed datetime `2026.11.05 12:34:56`. Each entry was inspected in an empty buffer
with a fresh session, outside math/Beamer/figure environments. Markdown literal
snippets were actually expanded to include their dynamic default placeholders.

Regex and postfix entries retain their metadata but omit literal text: their
output depends on captured input. The native parity check renders their callbacks
with representative captures; configured attached-UI and PTY tests exercise actual
matching and expansion. The Lua `snippet` authoring template also omits old text:
it intentionally emits native definitions after migration.

Do not regenerate this fixture from native snippets to make a failing comparison
pass. Changes to defaults should be deliberate and reviewed against this baseline.
