# Native snippet collections

Markdown and TeX default to `snippet-tools`. The other filetypes retain LuaSnip.
`:SnippetEngine luasnip`, `:SnippetEngine snippet-tools` and `:SnippetEngine auto`
switch the current buffer; `:SnippetEngineToggle` toggles the engines. Global
LuaSnip definitions such as `date`, `datetime` and TODO comments remain available.

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
