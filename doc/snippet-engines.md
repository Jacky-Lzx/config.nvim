# Markdown snippet engine trial

Markdown and `markdown_inline` default to the local `snippet-tools.nvim` engine.
Other filetypes default to LuaSnip. The original LuaSnip Markdown collection is
retained for immediate comparison.

Restart Neovim once after updating these plugin specs. Subsequent switches do
not require a restart:

```vim
:SnippetEngine
:SnippetEngine snippet-tools
:SnippetEngine luasnip
:SnippetEngineToggle
:SnippetEngine auto
```

Overrides apply to the current buffer. `auto` restores the filetype default.
Switching preserves text and clears both engines' active sessions and stored
selections. It also closes the completion menu so stale candidates are not used.

The migrated definitions are in `lua/snippet_collections/markdown.lua`; the
original comparison collection is `lua/snippets/markdown.lua`. The dispatcher
lives in `lua/integrations/snippets.lua`.

Both modes use the existing completion menu. Tab/Enter confirm a candidate,
Tab/Shift-Tab jump when no candidate is being accepted, and Alt-l/Alt-h always
navigate snippet fields. Alt-j/Alt-k retain menu navigation while the menu is
open and cycle choices through their fallback mapping otherwise. Alt-c opens
the choice picker. In Visual mode, backtick cuts the selection for the next
snippet, preserving the existing wrapping workflow.

In snippet-tools mode, inherited TeX and global LuaSnip definitions remain
available. Migrated literal definitions take precedence on duplicate labels.
LuaSnip's Markdown collection is excluded from that mode, and its TeX `mk`/`dm`
automatic triggers defer to the migrated Markdown versions. In LuaSnip mode the
original Markdown definitions and automatic triggers are restored.

Try these cases in a Markdown buffer:

- `bold`, `link`, `code`, `figure`, `todo`, `hide`, `detail`, confirming with Tab or Enter.
- For `figure`, enter `my_figure.png`; Alt-l selects the generated `my figure` description.
- `#3 `, `table2x2 `, `item3 `, `enum3 ` automatically generate the original layouts.
- `mk` and `dm` create inline/display math outside existing math.
- Select text, press backtick, type `bold`, and confirm to wrap it.
- Switch engines in the same buffer and repeat the same inputs.

`SnippetToolsInspect` shows the new engine's session state. `SnippetEngine` shows
the configured route; inherited LuaSnip snippets can still own the current field
inside snippet-tools mode.

Regression checks:

```sh
sh tests/smoke.sh native
python3 tests/snippets_tui.py
```

`tests/snippets.lua` runs the larger attached-UI scenario suite using the real
configuration and sibling plugin checkouts. The smoke integration suite supplies
its environment and isolated lockfile.
