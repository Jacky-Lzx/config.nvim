# Configuration architecture

## Ownership

- `init.lua` invokes `config.setup()`. `config/` owns startup composition, platform
  settings, selection, and plugin-manager bootstrap.
- `core/` owns editor options, general mappings, commands, and autocmds.
- `features/` owns capability behavior and state. Native folding, column guide,
  LSP/diagnostic behavior, and completion source selection can run without plugin APIs.
- `plugins/` owns lazy.nvim specs, dependencies, loading conditions, and plugin-specific
  configuration. Small callbacks used by only one plugin remain with that spec.
- `integrations/` connects feature behavior to plugin APIs. Snacks diagnostic toggles,
  Blink completion actions, and Blink/pairing Enter composition live here.
- `languages/` owns language metadata and language-specific plugin contributions.
  Selection, installation, and health checks must consume the same metadata.
- `after/lsp/` owns native server overrides. The language registry only selects servers.
- `ftplugin/` owns settings needed before runtime ftplugins. Neovim 0.12 loads Lua
  ftplugins after Vimscript ftplugins per runtime directory, so the configuration's
  Lua hooks run before the built-in scripts. Markdown style and Python/Rust mapping
  switches belong here; these hooks must not set `b:did_ftplugin` and skip the defaults.
- `after/ftplugin/` owns buffer options and buffer-local mappings applied after runtime defaults.
- `config/platform.lua` declares shared defaults and per-platform settings as a data table.
- `utils/` holds shared helpers: `utils/paths.lua` locates checkout-relative resources;
  `utils/platform.lua` selects platform settings, resolves environment overrides and
  executable availability, and runs system commands.
- Snippets, Tree-sitter queries, and Overseer templates keep their native discovery paths.

## Lifecycle

Set options and early globals, register editor behavior and LSP attach handlers, then
initialize lazy.nvim. Plugin APIs run in their plugin's lifecycle. Register UI integrations
on explicit events, not scheduled callbacks used as dependency ordering.

Requiring a feature or its adapter must not start plugins or register behavior. Native
behavior is installed through `setup()` or an attach handler. Adapters are invoked by
plugin lifecycle hooks or user actions; Snacks is passed explicitly to its diagnostic
adapter, while Blink configuration is read only when a completion action runs.

Platform settings remain declarative: loading `config.platform` does not inspect the machine
or start jobs. `utils.platform` matches each platform's `sysname`, falls back to `other`, and
overlays its fields on `defaults`. Lists are replaced as a whole. Environment overrides and
executable availability are evaluated when an accessor is called; changing the configuration
table requires a Neovim restart. Python project interpreter selection remains dynamic.
`languages/python/interpreter.lua` owns the live project interpreter provider; the
venv-selector lifecycle connects it through `integrations/python_environment.lua`.
Platform discovery accepts the selected path as data and handles executable/environment
fallbacks without inspecting plugin state. Tasks and `:make` use the language accessor.
Native LSP mapping removal runs in `features.lsp.setup()`, independent of Snacks events.

Obsidian workspace paths belong to the vault's `.lazy.lua`, not platform settings. The
shared spec provides plugin behavior and checks `opts.workspaces` after lazy.nvim merges
the local spec. Without a configured workspace, Obsidian remains disabled.

Conform owns `<leader>gf` globally and uses configured formatters with LSP fallback.
LSP attachment must not replace this mapping with a buffer-local native formatting action.
Diagnostic getters/setters are shared by native mappings and Snacks toggles, so connecting
Snacks preserves the current diagnostic state.

LSP configuration depends on blink.cmp so its native capability registration runs before
`vim.lsp.enable()`. Completion has one setup owner. which-key integrations run through
declared dependencies or synchronous module loading in filetype hooks.

Pairing declares `Jacky-Lzx/pairs.nvim` with lazy.nvim's `dev = true`. The shared `dev.path`
comes from `NVIM_DEV_PLUGIN_ROOT` (default `~/Documents/Github/nvim_plugins`), and
`dev.fallback = true` selects the GitHub version pinned in `lazy-lock.json` when the local
`pairs.nvim` directory is absent. Pairing and LuaSnip load on `InsertEnter`, while
`integrations/blink_pairs.lua` composes Enter after completion confirmation. lazy.nvim owns
source selection; `:checkhealth pairs` provides the plugin's own diagnostics. Plugin source
is not copied into this repo.

Blink's provider and menu plugins are module-loaded when completion actually uses
them. Copilot loads through its Blink provider or `:Copilot`; command-line completion
does not initialize pairing, snippets, or AI. LSP still depends on Blink so capability
negotiation is complete before servers start.

Use `specs` for optional configuration contributions and `dependencies` only when
loading order is required. Language DAP contributions supply options without adding
filetype triggers. The file tree configures its file-operation integration before
the first tree window opens; LSP attachment alone does not load the tree.

VimTeX loads at startup so headless inverse-search clients can invoke its global
command. Its buffer behavior remains filetype-driven. Conform's initial formatting
toggle is registered before its first save trigger, so opting out does not load the
formatter. Alignment, textobjects, surround, and operators load on their first keys;
file decorations load on file read/create and search decorations on first search.

A language definition must not register autocmds, mutate globals, run external commands, or
install dependencies while being read. Its plugin specs may do these things in explicit
lifecycle hooks. Tool/parser installation remains an explicit user command.

Profiles select languages; feature switches select AI, debugging, tasks, and sessions.
Unknown profile/feature names should fail with an actionable error. Disabling a language
removes its servers, tool contributions, and dedicated plugins; basic filetype behavior
may remain.

## Migration and validation

Runtime directories contain active configuration only. The former `config/legacy/`
modules and unimported `plugins/disable/` collection were removed after migration;
their exact previous contents remain in Git commit `f68a371`. To inspect an old spec,
use `git show f68a371:lua/plugins/disable/<name>.lua` rather than restoring an entire
inactive import tree. Candidates included Avante, Bufferline, Comment.nvim, copilot-lsp,
im-select, llm.nvim, Minuet, Neo-tree, neoconf, Sidekick, smear-cursor, and treesitter-context.
Reintroduce a chosen plugin in its current capability group with explicit lifecycle rules.

1. Make startup and editor behavior explicit.
2. Group plugin specs by purpose and introduce feature selection.
3. Consolidate language metadata; share it with tool installation and health checks.
4. Preserve and verify Vue and LaTeX integration behavior.

Use fixed profile fixtures for registry tests. Compare resolved plugin/tool/formatter
configuration against the pre-migration baseline. Check real startup and representative
filetypes with installed plugins, without installing or updating dependencies.
`tests/smoke.sh native` isolates plugin data and development roots, exercising native behavior
and contracts with plugin APIs mocked. `tests/smoke.sh integration` exercises installed plugins,
parser queries, startup profiles, and actual input. The default `all` entry runs both suites.
Integration checks also require Python 3 and a POSIX PTY. `tests/tui.py` exercises
the real `UIEnter` and `VeryLazy` path, cold command/key entry points, first-save
formatting control, and deferred completion/debugging/tree integrations. Ordinary
headless startup does not emit `UIEnter` and cannot cover that path by waiting.
`PROF=1 nvim` keeps the Snacks profiler running through the synchronous `VeryLazy`
handlers instead of stopping at `VimEnter`.

## Language metadata API

`config/inspect.lua` builds fresh diagnostic snapshots for `config.info()` and health checks.
Selected servers and enabled servers are separate fields. Tool paths are resolved live;
plugin sources/directories/loading states come from the already-loaded lazy.nvim registry.
Inspection never starts a plugin, installs dependencies, or mutates the active context.

`languages.resolve(selection)` returns a fresh aggregate for a fixed selection;
`config/selection_schema.lua` validates selection without loading languages or the
active context. Both independent language resolution and context composition use it.
`config.context.initialize(selection)` resolves the active selection and language data once.
`config.setup()` obtains this context before editor behavior or lazy.nvim imports, reusing
an explicitly initialized selection when present. Every consumer, including `languages.current()`, reads this
same context. A later different selection fails explicitly; restart after changing profiles.
`config.context.resolve(selection)` produces independent contexts for validation.
`config/specs.lua` imports shared feature groups and appends the active language specs.

Resource paths use `utils.paths.config(...)`, anchored to the checkout containing that
module instead of an unrelated default `stdpath("config")` when using an explicit init file.

Large plugin collections retain native lazy.nvim imports: completion core, menu, and source
contributions live in `plugins/coding/completion/`; Markdown integrations live in
`languages/markdown/specs/`. Mini plugins have individual feature-owned specs. Shared
completion source cycling/toggling lives in `features/completion/init.lua` and accepts
provider configuration as data, keeping buffer state separate from global provider defaults.
`integrations/blink_completion.lua` reads Blink's configuration and displays the selected sources.

A language may declare:

| Field | Consumer |
| --- | --- |
| `servers` | nvim-lspconfig enables these native LSP config names |
| `parsers` | Tree-sitter's explicit installation command |
| `tools` | Mason installation and `checkhealth config` |
| `formatters`, `formatter_options` | Conform filetype assignments and custom formatter settings |
| `linters`, `linter_options` | nvim-lint assignments and static custom linter settings |
| `plugins` | Native lazy.nvim specs or targeted imports for complex integrations |
| `requires` | Optional executable requirements for filetype formatter/linter bindings |

A tool has a `mason` package name (optional), an `executable` name or a `resolve` function,
an optional `feature` requirement, and an optional `post_install` callback. System requirements
and managed packages are deduplicated separately so a system requirement cannot suppress a
later language's package installation. Health checks deduplicate executable checks.

Conflicting filetype formatter/linter definitions fail explicitly. Shared plugin setup runs
once in `plugins/coding/`; language contributions never call the same plugin's setup again.
A custom linter needing plugin APIs (Verilog's parser) can use a language plugin `opts` hook.

`languages/schema.lua` checks declaration fields, types, feature names, and tool identity.
Linter bindings must be contiguous lists of non-empty names. Formatter bindings use the
same list shape plus Conform's typed filetype options (`stop_after_first`, `quiet`,
`timeout_ms`, `lsp_format`, `id`, `name`, `filter`, and `formatting_options`). Unknown
options, sparse indices, and invalid option types fail while reading the declaration.
Duplicate tools must have identical definitions; conflicts report both language owners.
Optional bindings use `requires = { formatters = { html = "html_beautify" } }` rather than
probing the machine while requiring a definition. `languages.resolve(selection, capabilities)`
accepts an executable resolver for deterministic availability tests; production uses the
platform resolver and probes each requirement once per resolution.

## Preserved defaults and deliberate corrections

All existing default profiles, including `optional`, remain enabled. Default plugin, Mason,
parser, formatter, linter, and DAP selections were compared with the original resolved specs.

- KDL no longer falls back to being treated as an LSP server name.
- LaTeX math insertion mappings are buffer-local.
- VimTeX globals are set in `init`, before its filetype scripts run.
- Custom theme highlights reapply on colorscheme changes.
- Lua completion and AI completion integrations follow their owning language/feature.
- Snippet discovery uses the configuration path, independent of the working directory.

No plugin versions were updated. Integration checks use installed plugins with external LSP
startup stubbed; live server responses, PDF tools, and actual debugger sessions need separate
interactive verification when those integrations change.
