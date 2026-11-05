# Native snippets

All filetypes use the local `snippet-tools.nvim` engine. The 154 personal snippets
live in `lua/snippet_collections/`: global date/time and TODO comments, Lua, Python,
Rust, Typst, Verilog/SystemVerilog, Markdown and TeX. LuaSnip, its old definitions
and the engine-switch commands have been removed. Restart Neovim after updating
the plugin specs.

The adapter in `lua/integrations/snippets.lua` connects native snippets to the
completion menu and LSP expansion. Markdown inherits TeX; `markdown_inline` inherits
Markdown, and SystemVerilog inherits Verilog. On duplicate completion labels, the
highest-priority definition wins.

Tab/Enter confirm a completion candidate. Tab/Shift-Tab jump when no candidate is
being accepted; Alt-l/Alt-h always navigate snippet fields. Alt-j/Alt-k navigate the
completion menu while it is open and cycle snippet choices otherwise. Alt-c opens
the choice picker. Visual backtick cuts text for the next snippet's selected-text
field. Choice and dynamic branches retain edits when switched or regenerated.
Complex choices first select the entire branch; Alt-l then enters its fields.

Commands:

- `:SnippetToolsInspect` shows the active session.
- `:SnippetToolsStop` stops the active session.
- `:SnippetToolsReload` reloads definitions without duplicate entries. Active fields
  remain editable; new expansions use the reloaded definitions.

Useful Markdown checks:

- Complete `bold`, `link`, `code`, `figure`, `todo`, `hide` or `detail`.
- In `figure`, enter `my_figure.png`; Alt-l selects the generated `my figure` label.
- Type `#3 `, `table2x2 `, `item3 ` or `enum3 ` for generated layouts.
- Type `mk` or `dm` outside existing math for inline/display math.
- Select text, press backtick, type `bold` and confirm to wrap it.

`tests/snippet_collections.lua` compares every definition's trigger, priority, word
boundary and default text with the frozen original export in
`tests/fixtures/snippets-legacy.json`. The fixture README records its provenance
and exceptions. No test needs an installed LuaSnip checkout.

```sh
sh tests/smoke.sh native
sh tests/smoke.sh integration
```

Integration checks include attached-UI scenarios in `tests/snippets.lua` and
`tests/latex_snippets.lua`, plus real terminal input and intermediate screen states
in `tests/snippets_tui.py` and `tests/latex_snippets_tui.py`.
