# Configuration architecture

## Ownership

- `init.lua` expresses startup order. `config/` owns editor options, global behavior,
  platform discovery, selection, and plugin-manager bootstrap.
- `plugins/` owns shared plugin mechanisms, grouped by feature. Specs use lazy.nvim's
  native `opts`, `keys`, dependencies, and lifecycle hooks.
- `languages/` owns language metadata and language-specific plugin contributions.
  Selection, installation, and health checks must consume the same metadata.
- `after/lsp/` owns native server overrides. The language registry only selects servers.
- `after/ftplugin/` owns buffer options and buffer-local mappings. Files that must run
  before runtime ftplugins should be retained explicitly and documented.
- `config/platform.lua` owns environment overrides and capability discovery.
- Snippets, Tree-sitter queries, and Overseer templates keep their native discovery paths.

## Lifecycle

Set options and early globals, register editor behavior and LSP attach handlers, then
initialize lazy.nvim. Plugin APIs run in their plugin's lifecycle. Register UI integrations
on explicit events, not scheduled callbacks used as dependency ordering.

LSP configuration depends on blink.cmp so its native capability registration runs before
`vim.lsp.enable()`. Completion has one setup owner. which-key integrations run through
declared dependencies or synchronous module loading in filetype hooks.

Pairing uses an external local plugin checkout, with one availability check shared by
the lazy spec, completion integration, and health report. Missing pairing must not
prevent completion loading or ordinary Enter. Plugin source is not copied into this repo.

A language definition must not register autocmds, mutate globals, run external commands, or
install dependencies while being read. Its plugin specs may do these things in explicit
lifecycle hooks. Tool/parser installation remains an explicit user command.

Profiles select languages; feature switches select AI, debugging, tasks, and sessions.
Unknown profile/feature names should fail with an actionable error. Disabling a language
removes its servers, tool contributions, and dedicated plugins; basic filetype behavior
may remain.

## Migration and validation

1. Make startup and editor behavior explicit.
2. Group plugin specs by purpose and introduce feature selection.
3. Consolidate language metadata; share it with tool installation and health checks.
4. Preserve and verify Vue and LaTeX integration behavior.

Use fixed profile fixtures for registry tests. Compare resolved plugin/tool/formatter
configuration against the pre-migration baseline. Check real startup and representative
filetypes with installed plugins, without installing or updating dependencies.

## Language metadata API

`languages.resolve(selection)` returns a fresh aggregate for a fixed selection;
`config.context.initialize(selection)` resolves the active selection and language data once,
before lazy.nvim imports specs. Every consumer, including `languages.current()`, reads this
same context. A later different selection fails explicitly; restart after changing profiles.
`config.context.resolve(selection)` produces independent contexts for validation.
`config/specs.lua` imports shared feature groups and appends the active language specs.

Resource paths use `config.paths.config(...)`, anchored to the checkout containing that
module instead of an unrelated default `stdpath("config")` when using an explicit init file.

A language may declare:

| Field | Consumer |
| --- | --- |
| `servers` | nvim-lspconfig enables these native LSP config names |
| `parsers` | Tree-sitter's explicit installation command |
| `tools` | Mason installation and `checkhealth config` |
| `formatters`, `formatter_options` | Conform filetype assignments and custom formatter settings |
| `linters`, `linter_options` | nvim-lint assignments and static custom linter settings |
| `plugins` | Native lazy.nvim specs or targeted imports for complex integrations |

A tool has a `mason` package name (optional), an `executable` name or a `resolve` function,
an optional `feature` requirement, and an optional `post_install` callback. System requirements
and managed packages are deduplicated separately so a system requirement cannot suppress a
later language's package installation. Health checks deduplicate executable checks.

Conflicting filetype formatter/linter definitions fail explicitly. Shared plugin setup runs
once in `plugins/coding/`; language contributions never call the same plugin's setup again.
A custom linter needing plugin APIs (Verilog's parser) can use a language plugin `opts` hook.

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
