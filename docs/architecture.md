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
