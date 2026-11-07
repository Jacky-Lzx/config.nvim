# Keymaps

[Quick start](../README.md) · [Architecture](architecture.md)

## Toggle shortcuts

Persistent toggles use `Space t`, then a group and a leaf. The prefixes themselves
have no feature action. `lua/config/toggle_keys.lua` is the single layout source;
feature owners still own behavior and state. Old toggle aliases are removed.

| Prefix | Group | Leaves |
| --- | --- | --- |
| `Space t e` | Editor | `w` wrap, `s` spelling, `n` line numbers, `r` relative numbers, `c` conceal, `t` Tree-sitter |
| `Space t u` | UI | `i` indent guides, `d` dimming, `z` Zen, `m` Zoom, `a` animation, `s` smooth scroll, `b` dark background |
| `Space t g` | Git | `b` blame, `w` word diff, `s` signs, `o` inline diff, `d` diff view |
| `Space t l` | LSP / diagnostics | `d` diagnostics, `v` virtual text, `l` virtual lines, `h` inlay hints |
| `Space t f` | Formatting | `a` autoformat on save |
| `Space t p` | Pairs | `e` automatic pairing |
| `Space t m` | Markdown | `r` rendering |
| `Space t i` | Images | `a` automatic image/formula preview |
| `Space t x` | TeX | `a` automatic build on save; available in TeX/BibTeX buffers |
| `Space t d` | Debug / performance | `p` profiler, `h` profiler highlights |
| `Space t w` | Windows / panels | `f` file tree, `t` tasks, `s` shell, `d` diagnostics, `l` locations, `c` loclist, `q` quickfix, `o` outline, `a` optional DAP view |

These are Normal-mode feature controls. Editing actions such as comment/checkbox
changes and LaTeX environment stars keep their editing keys. Completion-menu keys
remain local interactions, including Insert-mode `Alt-i` for Copilot.

Toggle descriptions and state are registered with keymap-tools alongside their feature
owners. Hints and the mapping picker share `Enable` / `Disable` descriptions, and
`require("keymap_tools").list()` exposes `item.toggle.name` and `item.toggle.state`.
Status reads do not activate lazy Git, pairing, Markdown or image providers; unavailable
state displays a neutral `Toggle` description. Window, buffer, tab and session state
follow the actual switch scope. Diagnostics and formatting keep their native mappings
when feature providers initialize. Switches are registered by their explicit owner,
without matching descriptions or replacing global mapping hooks.

`<leader>sk` and `Ctrl+/` open the same searchable, executable keymap picker in Normal, Visual and
Insert modes. `Space+?` remains available in Normal and Visual modes. The picker
uses the source buffer's effective mappings for that mode and restores the Visual
selection or Insert position on cancellation. `Ctrl+_` also opens it for terminals
that encode `Ctrl+/` using the legacy control code.
Inside a selection-tools input, it opens a temporary child: search and execute
the parent's mappings, or cancel to resume the original query and selection.
Both buffer and global mappings are shown by default, with buffer mappings
first. `Alt+b` toggles buffer mappings and `Alt+g` toggles global mappings while
preserving the query; the title shows the current filters.
Pressing `Ctrl+/` again inside the keymap search returns to the parent.

## Shortcut and command ownership

Plugins publish Lua actions, namespaced commands and optional `<Plug>` endpoints.
Global entry keys and ordinary filetype/LSP buffer keys belong to this config.
Use `config.bindings.set(owner, entries)` for declarative mappings; keep language
keys beside their language configuration. Plugin-owned windows retain their local
interaction keys. Completion, pairing and snippet input adapters stay explicitly
configured with their feature because they compose confirmation and fallback.

LSP and LaTeX buffer mappings use `config.bindings.set_buffer(owner, buffer, entries)`.
It scopes entries to that buffer, removes declarations on wipeout and preserves
later manual replacements during cleanup. Repeated LSP attachment keeps the
buffer's existing mappings. Functional tests invoke the owning Lua API directly;
keyboard interaction tests declare their own fixture mappings.

editing-tools and tex-tools no longer assign user keys by default. This config
binds their public endpoints; explicit plugin mapping presets remain opt-in.
ui-tools also leaves scroll and mouse entry keys to configuration. Scroll bindings
follow `<leader>tS`, preserving custom mappings when enabled or disabled.

Formal commands remain implemented by their owning plugins, including argument
validation and completion. Registration reports same-name conflicts, repeated
setup refreshes plugin-owned definitions, and cleanup preserves user replacements.
Configuration may define separate aliases such as `StartupTime`, `VenvSelect` and
`Outline`; it must not redefine plugin commands such as `ImageInsert`. Existing
plugin command names are retained in this migration.
