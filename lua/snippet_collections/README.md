# Native snippet collections

All filetypes default to `snippet-tools`, including Lua, Python, Rust, Typst,
Verilog/SystemVerilog, Markdown and TeX. Date/time and signed TODO comments are
native global definitions. Normal completion, automatic expansion, navigation
and Visual capture do not load LuaSnip.
`:SnippetEngine luasnip`, `:SnippetEngine snippet-tools` and `:SnippetEngine auto`
switch the current buffer; `:SnippetEngineToggle` toggles the engines. LuaSnip
loads only when explicitly selected or opened through its commands, using the
retained definitions under `lua/snippets/` for comparison. Sources are never mixed;
returning to `auto` selects the native engine for every filetype.

The native Lua `snippet` template now writes snippet-tools definitions. Other
migrated language/global triggers and default text are checked against the retained
collections in `tests/snippet_collections.lua`. Dynamic module names, computed
Typst labels, Verilog mirrors and TODO alias/signature choices use native nodes.

`tex.lua` loads 92 migrated definitions from `tex/text.lua`, `environments.lua`,
`math.lua` and `beamer.lua`. Their trigger names, priorities, word boundaries and
default text are checked against the retained files under `lua/snippets/tex/`.
The postfix patterns match the same characters as the original LuaSnip postfix
helper. Math/environment/Beamer predicates share the existing context detector;
loading the native collection does not require LuaSnip. Markdown inherits this
native TeX collection, with its own `mk`/`dm` layout taking precedence.

Use the existing `<A-l>` / `<A-h>` navigation, `<A-j>` / `<A-k>` choices and `<A-c>`
choice picker. Complex choices stop on their whole branch first: `<A-l>` enters
the branch's editable fields (for example a frame title or RGB components).
This follows the new engine's navigation model and can add a stop compared with
LuaSnip. Choice and dynamic branches retain edits when switched or regenerated.
`:SnippetToolsReload` re-executes the TeX definition modules without duplicates.

Validation lives in `tests/latex_snippet_collections.lua` (definition parity and
reload), `tests/latex_snippets.lua` (real configured attached UI), and
`tests/latex_snippets_tui.py` (native terminal input and intermediate visible
states). They run in the integration section of `tests/smoke.sh`; Markdown's
existing snippet tests remain enabled.
