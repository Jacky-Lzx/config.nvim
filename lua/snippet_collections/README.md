# Native snippet collections

All snippets run on `snippet-tools.nvim`. Each file returns native definitions;
`helpers.lua` centralizes definition defaults. LuaSnip and its old definition tree
have been removed.

The collection contains 154 definitions across global, Lua, Python, Rust, Typst,
Verilog, Markdown and TeX files. SystemVerilog inherits Verilog, Markdown inherits
TeX, and `markdown_inline` inherits Markdown. Global definitions provide date/time
and signed TODO comments. `utils/commentstring.lua` chooses comment delimiters from
the deepest injected language at the cursor, falling back to the buffer setting.

`tex.lua` loads 92 definitions from `tex/text.lua`, `environments.lua`, `math.lua`
and `beamer.lua`. `tex/context.lua` owns math/environment/Beamer predicates;
`tex/helpers.lua` composes them with native tex-tools context and postfix matching.
Markdown's own `mk`/`dm` layouts take priority over inherited TeX definitions.

The Lua `snippet` template generates native definitions. Dynamic module names,
computed labels, mirrors and TODO alias/signature choices use native nodes.
The frozen export in `tests/fixtures/snippets-legacy.json` records the original
trigger metadata and default text, with provenance in its adjacent README.
`tests/snippet_collections.lua` compares all 154 definitions without loading the
old engine; TeX's collection test also checks callbacks and stable reloads.

Use Alt-l/Alt-h to navigate, Alt-j/Alt-k to cycle choices and Alt-c for the choice
picker. Complex choices stop on the whole branch before its editable fields.
Choice and dynamic branches retain edits when switched or regenerated.
Visual backtick captures text for the next snippet. `:SnippetToolsReload`
re-executes collection files, including TeX children, without duplicate entries.

See [the workflow guide](../../doc/snippet-engines.md) for completion behavior and
[the smoke runner](../../tests/smoke.sh) for configured attached-UI and PTY checks.
