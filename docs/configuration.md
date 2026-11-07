# Configuration

[Quick start](../README.md) · [Architecture](architecture.md)

## Profiles and features

Edit `lua/config/selection.lua` to select language profiles and optional workflows:

```lua
return {
  profiles = { "base", "web", "native", "data", "writing", "optional" },
  features = { ai = true, debugging = true, tasks = true, sessions = true },
}
```

All six profiles are currently enabled, preserving the existing personal configuration.
Profile membership is defined in `lua/config/profiles.lua`:

- `base`: Lua, Bash, JSON, YAML, TOML, KDL, Nix
- `web`: HTML, Vue, JavaScript, TypeScript
- `native`: C, C++, CMake, Rust, Swift
- `data`: Python
- `writing`: Markdown, LaTeX, Typst
- `optional`: Java, Verilog, Godot, Matlab

Remove profiles or define smaller ones to narrow language support. Set a feature to `false`
to disable that workflow, including its statusline/completion integrations. Restart Neovim
after changing the selection; profiles are resolved once per process.

Only selected languages contribute servers, tools, formatters, linters, parsers, and dedicated
plugins. Basic filetype settings and shared snippets remain available. Debug adapters are
included in tool installation only when debugging is enabled. KDL currently has no LSP.

Run `:ConfigToolsInstall` after changing profiles. Tool and parser installation is explicit and
may access the network. Normal startup does not install tools or Tree-sitter parsers.
The command now uses the local `toolchain-tools.nvim` checkout under the development plugin root.
`:ToolchainPlan` inspects requirements, `:Toolchain` shows tasks and logs, and `:ToolchainRetry`
retries failed/unavailable tasks. The legacy `:MasonToolsInstall` and `:TSInstallConfigured`
commands submit only the independent `tool` and `parser` providers to the same queue. Extra `codespell` and
`regex` requirements are preserved. Parser requirements now use the independent `parser`
backend: pinned Git sources, matched query data, CLI compilation and validation, with
version receipts and repair on explicit installation. The custom LaTeX grammar is pinned
in `languages/latex/plugins.lua`. Restart Neovim after parser installation to activate it.

Toolchain activates immutable parser/query runtime paths at startup; highlighting is owned
by `features/treesitter.lua`. Toolchain now also registers parser
filetype aliases and query predicate compatibility. The nvim-treesitter main plugin is no
longer declared or loaded; Markdown rendering depends on toolchain instead.
The independently installed runtime covers all 45 previously installed parser languages,
including Vimdoc, XML, TSX and Svelte. `editing-tools.nvim` owns text objects,
editing operators, alignment and bundled textobject queries.
`nvim-treesitter-textobjects` is no longer a plugin dependency. `:TSInstallConfigured` submits independent parser tasks. Query data is downloaded
at a fixed nvim-treesitter commit without loading its Lua code; existing legacy checkout
files are retained for rollback but are not required by these managed language bundles.
When migrating an existing installation, old `site/queries` links to that checkout must
be moved outside the runtime path after their languages have managed bundles: Neovim
reads inheritance headers in lower-priority query files too. This machine retains those
links and their manifest under `toolchain-tools/legacy-queries` in the Neovim data directory.
Use `:ToolchainLog` for build logs and `:ConfigToolsInstall` to check/install the current
profile's pinned versions; the old plugin's other `:TS*` commands are no longer registered.

Editing loads from the development plugin root on the first object/operator key or
`:EditingTools`. `i`/`a`, `in`/`an`, `il`/`al` select objects; `cr`, `gx`, `gm`, `gs`,
`g=` replace, exchange, duplicate, sort and evaluate arithmetic. `ga` opens an
alignment preview: Enter applies, Esc cancels, and `d` changes the delimiter.
Confirmed edits support `.` repeat and undo. `gX` keeps Vim's URI opener available.
The former `gA` immediate-alignment mapping is no longer installed. Pair insertion
and surround continue to belong to pairs.nvim. Visual `mI` / `mA` now use
editing-tools' live insertion sessions, replacing multicursor.nvim. They insert at
each line's first nonblank/end, or at the selected block's left/right column.
Unicode, register insertion, pair mappings and newlines synchronize live. Escape
or Ctrl-C ends the session; undo/redo follows the native insertion block. Tab
expansion and short-line padding share that undo block. This covers the configured
insertion workflow rather than a general Normal-mode multi-cursor engine.

Mason is no longer declared or loaded. Toolchain installs pinned release archives, isolated
npm/Python packages, Cargo packages and selected source builds. It appends managed tool
directories after the existing PATH. Old Mason packages remain untouched for rollback but
are not consulted. New npm/Python installs record resolved dependency locks, reused during
repairs; initial transitive resolutions are not globally locked. `:Mason` opens the unified tool
manager and `:MasonToolsInstall` remains an installation alias. Use `:ToolchainLog` for
logs; the other old `:Mason*` commands are no longer registered.

`toolchain-lock.json` freezes the managed fallback recipes, release digests and
npm/Python/Cargo dependencies per platform. Normal installation uses the frozen
record and never rewrites it. `:ToolchainLock!` explicitly resolves configured
managed tools and updates the current platform's record; commit that change.
`:ToolchainLock` exports existing verified managed versions. Missing platform or
package entries require an explicit lock update; system/Nix tools retain priority.
Python fallback installs require the interpreter major/minor recorded in the lock.

`:ToolchainVersions [tool:name]` lists stored versions; `:ToolchainRollback tool:name <id>`
verifies and selects a previous version. Restart affected clients afterward. Rollback leaves
`toolchain-lock.json` unchanged. `:ToolchainPrune [tool:name]` previews retired versions and
explains protections for current versions, live editors and active installers; it deletes
nothing. Reports close with `q`.

## Adding a language

1. Add `lua/languages/<name>.lua` returning metadata (see `lua/languages/json.lua`).
   Complex languages can use `<name>/init.lua` and `<name>/plugins.lua`.
2. Add the language name to a profile in `lua/config/profiles.lua`.
3. Put server-specific overrides, if needed, in `after/lsp/<server>.lua` and buffer-local
   behavior in `after/ftplugin/<filetype>.lua`. Put switches read by runtime ftplugins
   in `ftplugin/<filetype>.lua` so they are set before the built-in scripts run.
4. Run `./tests/smoke.sh`, restart Neovim, and explicitly install any new tools.

Language `tools` entries distinguish managed `package` names from executable names. Omit `package`
for system-managed tools; use `resolve` for non-PATH tools such as debugpy's Python interpreter.
Installation and health checks consume this same list. Language definitions must not install
anything or register editor behavior while being read; use plugin lifecycle hooks instead.
Declarations are schema-checked, and conflicting definitions of the same tool fail explicitly.
For optional formatter/linter bindings, declare executable requirements in `requires`;
the resolver checks availability rather than freezing it when the language module is loaded.

## Platform configuration

`lua/config/platform.lua` returns a configuration table with `defaults`, `macos`, `linux`,
and `other` entries. Edit a platform entry to override shared defaults, for example:

```lua
linux = {
  sysname = "Linux",
  shell = { "bash", "fish" },
  opener = { "xdg-open" },
  dev_plugin_root = "~/code/nvim_plugins",
},
```

Overrides replace entire fields, including command lists. `sysname` matches the operating
system name reported by libuv. Managed package/resource paths are resolved by toolchain;
user paths support `~`. Restart Neovim after changing these settings.

`lua/utils/platform.lua` selects the platform, resolves executables, and runs system commands.
Consumers use `require("utils.platform")`. Unknown operating systems use `other` and the shared defaults.
The following environment variables override local paths or commands:

- `NVIM_SHELL`
- `NVIM_PYTHON3_HOST_PROG`
- `NVIM_DEBUGPY_PYTHON`
- `NVIM_OPEN_CMD`
- `NVIM_DEV_PLUGIN_ROOT`

macOS uses `open`; Linux uses `xdg-open`. LaTeX PDF viewing is configured in
`lua/languages/latex/plugins.lua` (currently Pagewing), with build, preview and viewer
checks provided by `:checkhealth tex-tools`. Missing Delta or Kitty disables the
corresponding optional integration.

Obsidian workspaces belong to the vault's `.nvim-plugins.lua`, under the
`obsidian-tools.nvim` declaration's `opts.workspaces`. The new native plugin loads
only when a trusted project selects it and a Markdown buffer opens. It uses the
local `dev_plugin_root()/obsidian-tools.nvim` checkout and depends on
`markdown-tools.nvim` for shared syntax; the former third-party `obsidian.nvim`
is no longer selected. Its `assets/imgs` image defaults remain project-local.
Start Neovim inside the vault or one of its subdirectories to read the local spec.

`<leader>OO` opens the command menu; `Of`/`Oq` switch notes, `Og` searches,
`Od` follows a vault link, `Ob` shows backlinks, `Ot` selects tags, and `Op`
delegates image paste to image-tools. `On` creates a note, `ON` opens today's daily,
`OD` selects a daily, `OT` inserts a template, `Ol` inserts a note link, and `Or`
renames/moves a note and updates supported references. Rename takes a vault-relative
path and requires clean affected notes. `<localleader>Mf` delegates to the same
vault resolver. The completion-tools source supplies notes, aliases, headings,
block IDs and tags only inside the selected vault. Existing Enter/Tab ownership
is retained. See the plugin README for parser coverage and rename semantics.

Pairing uses [Jacky-Lzx/pairs.nvim](https://github.com/Jacky-Lzx/pairs.nvim) with plugin-tools'
`dev = true` and `dev.fallback = true`. It prefers `NVIM_DEV_PLUGIN_ROOT/pairs.nvim`
(default `~/Documents/Github/nvim_plugins/pairs.nvim`); when that directory is absent,
explicit `:PluginTools install` installs the GitHub version pinned in `plugin-tools-lock.json`. Completion tools composes Enter after completion confirmation. Use `:checkhealth pairs` for plugin diagnostics.
