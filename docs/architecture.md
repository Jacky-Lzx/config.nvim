# Configuration architecture

## Ownership

- `init.lua` delegates to `config.setup()`. `config/` composes startup, profiles,
  platform settings, plugin declarations and the pinned manager bootstrap.
- `core/` owns editor options, generic commands, mappings and autocmds.
- `features/` owns native file policy, folding integration, LSP/diagnostic behavior,
  bars data and completion source preferences. Large/minified files are classified
  before filetype consumers start expensive work.
- `plugins/` declares packages and applies personal options and mappings.
  `integrations/` connects plugin APIs and project-specific policies; the generic
  declaration collector does not implement Obsidian workspace behavior.
- `languages/` declares servers, parsers, tools, formatters, linters and plugin
  contributions. `lsp/` and `after/lsp/` provide native server definitions/overrides.
- `ftplugin/` supplies early filetype settings; `after/ftplugin/` applies buffer
  options and mappings after runtime defaults. These hooks retain native ftplugins.
- `utils.paths` locates resources relative to this checkout. `utils.platform`
  resolves declarative platform settings, environment overrides and executables.
- Native snippet definitions remain in `lua/snippet_collections/`; personal query
  extensions remain in `queries/`. Plugin code is never vendored into this checkout.

## Startup and plugin lifecycle

`config.setup()` registers the large-file policy, resolves the selected context,
sets editor options and native behavior, then starts plugin-tools. Startup does
not fetch Git repositories or install tools. `ConfigReady` follows configuration.

The manager resolves all declarations, mounts runtime directories, and runs each
root's `config(ctx)` or `main.setup(opts)` once. Plugins own their entry points
and defer expensive features internally. Completion, image and snippet frontends
register commands/events without immediately loading their full implementations.
There are no manager event/key/command proxies or require interception.

Feature plugin `setup(nil)`/`setup({})` starts from fresh defaults. Options are
copied, dictionaries merge recursively, and lists replace defaults (including an
empty list). Existing validation runs before replacing live resources; repeating
setup must not accumulate commands, callbacks, timers or observers. LSP tools
exposes `update(opts)` for explicit partial feature changes. Native server
definitions retain Neovim's overlay semantics and independent client ownership.

Where available, `disable()` is temporary and retains configuration;
`dispose()` releases owned resources and forgets feature configuration. Disposal
is safe when cold or repeated. Cleanup restores only registrations/options still
owned by that instance, preserving later user replacements, personal bindings
and buffer contents. Queued work must not revive a disposed instance. Explicit
subsequent use can initialize resources again.

Resource boundaries remain explicit: plugin-tools accepts singleton setup once
because native plugin scripts cannot be generically unloaded. Toolchain refuses
setup/disposal during installations or lock writes, and retains installed files,
activation paths and live-session leases. TeX disposal releases its integration
without cancelling server-owned builds or stopping native clients. A blocked
modified focus buffer can make UI disposal return `false` without forced deletion.
Keymap tools preserves caller-owned metadata/toggle registrations across runtime
disposal; their owners release those handles when their own feature unloads.

Resolving declarations must not bind keys or initialize plugins. `config(ctx)`
receives plugin-owned copies of options and registers ordinary personal mappings
through `config.bindings.set()`. Replacing registrations clears old owned mappings
and FileType callbacks while preserving manual/other-owner overrides.

Declarations use ordered lists. First appearance establishes a node's position;
children are traversed before the next sibling. Later contributions to the same
ID merge dictionaries recursively, replace lists, and can clear a key with an
empty table. Scalar declaration fields must agree. Merging completes before setup.
`dependencies` require availability; only `after` imposes initialization order and
activates its targets. Root nodes default to `start = true`, children to false.
Runtime directories follow first-declaration order, independently of `after`.

## Sources and installation

GitHub declarations use `owner/repo`. The shared `url_format` in
`config.plugins.settings()` selects HTTPS or SSH. `dev = true` prefers the external
checkout under `NVIM_DEV_PLUGIN_ROOT`; absent checkouts use the managed package
root. Personal plugins target `main` for updates and use exact locked commits for
installation. Managed Git checkouts are detached at their locked commits.

The manager itself prefers an explicit `NVIM_PLUGIN_TOOLS_PATH`, then its local
development checkout, then the immutable revision in `config/plugin_bootstrap.lua`.
Run `scripts/install-plugins.lua` explicitly with headless Neovim to prepare a new
machine. Installation does not start plugin features. Existing managed packages
can be reconciled with a changed lock using `:PluginTools restore`.

`plugin-tools-lock.json` owns plugin revisions. `toolchain-lock.json` separately
owns managed language tools. Toolchain installs immutable parser/query bundles
and tool versions; it does not own language behavior. System/Nix executables may
satisfy requirements without installing managed fallback packages. Installation,
local tests, Git commits, publication and hosted CI are distinct states.

## Selection and language metadata

`config.selection` chooses profiles and optional workflows. The selection schema
validates those fields without loading plugins. `config.context.initialize()`
resolves the active selection once; a later different selection requires restart.
`languages.current()` and all installation/health consumers read that context.
Independent `languages.resolve()` and `config.context.resolve()` calls support tests.

The collector imports shared groups, enabled workflows, language contributions,
then the trusted project's `.nvim-plugins.lua`. Integration adapters finalize
project-specific policy. `integrations.obsidian` enables Obsidian only when an
active contribution supplies workspaces, and contributes the vault image directory.
Workspace paths live in the vault's trusted project file, never platform settings.

Language fields describe servers, parsers, tools, formatter/linter bindings and
plugin contributions. Schemas reject malformed lists, unknown fields and conflicting
owners. Shared plugin configuration runs once; language contributions supply options.
Optional executable requirements are probed through the platform resolver, which
can be replaced in deterministic tests. Selected and enabled servers remain separate.

Python's interpreter accessor stays dynamic. workspace-tools environment selection
works independently of saved sessions; LSP, tasks and DAP consume the same accessor.
Child process environment changes do not mutate global PATH.

## Feature boundaries

completion-tools owns the completion UI and optional Copilot server connection;
snippet-tools owns snippets, choices, selection capture and completion integration.
pairs owns pairing. Their frontends handle first-use initialization. Command-line
completion and status inspection do not initialize unrelated engines or AI servers.

lsp-tools owns LSP semantics, requests and result validation; selection-tools owns
picker presentation and lifecycle; git-tools owns Git workflows and diff rendering.
File-tools owns filesystem operations, external opening and the tree. Its LSP
file-operation capabilities are available before servers start. Dependencies do
not imply that their user interfaces have initialized.

ui-tools owns bars, folds, annotations and window presentation. The configuration
supplies preferences and data callbacks. keymap-tools inspects native mappings,
provides hints and the executable picker, and accepts metadata from feature owners.
Read-only status queries must not activate providers. Git, UI and Debug toggle
integrations consume their owners' public `get_state` snapshots; unavailable state
remains unknown rather than initializing a provider.

TeX buffer mappings call tex-tools commands; LSP attachment does not redefine build,
log, cancellation or viewer actions. tex-tools owns TeX editing, builds, forward/inverse search, conceal and preview
selection. Formula compilation loads image rendering only when needed. The
configuration dispatches TeX preview to its unified API and other files to image-tools.
The selected parser and Neovim queries come from the pinned tree-sitter-latex fork.
Queries own math/path priorities; theme-tools owns TeX semantic colors. Buffer
attachment starts highlighting and preserves syntax fallback if the parser fails.

format-tools.nvim owns formatting execution, with native LSP fallback. The shared
format mapping is declared in its coding spec. LSP attachment must not replace
it. Diagnostic switches share the same native state. Tasks and workspace
persistence remain separate: sessions restore task definitions without
silently restarting processes.

## Validation and performance

`sh tests/smoke.sh native` isolates plugin data and runs offline native tests.
`sh tests/smoke.sh integration` exercises current defaults and critical real-PTY workflows.
`sh tests/smoke.sh compatibility` opts into optional plugins with fixed selections.
`sh tests/smoke.sh acceptance` exercises real local LSPs and installed fallback paths.
Historical snippet parity is an explicit `migration` suite, outside `all`.
Each check has isolated state and bounded lifetime; independent failures are
aggregated, with logs and a JSON summary retained. `--filter` selects a case and
`--keep` retains evidence even on success. Stable action IDs let workflow inputs
follow declared keys while expected results and ownership checks stay independent.
The configured lifecycle check verifies that invalid setup, repeated disposal
and reinitialization preserve personal bindings. Individual plugin repositories
exercise their setup/disposal contracts alongside their own headless and PTY tests.
`python3 tests/remote_install.py` explicitly installs pinned GitHub versions into
isolated directories and starts editors with development paths hidden. It checks
minimal/default startup and first-use public APIs; it requires network access.

`ConfigInfo` and `checkhealth config` report the already-resolved context without
starting plugins. Health checks distinguish optional/system/managed tools.

Performance work starts with fresh-process startup and actual first-use measurements.
Use interleaved real PTYs for visible behavior; verify cursor/mode/focus, burst input,
theme changes and asynchronous completion boundaries. Headless or isolated component
timings do not establish a visible startup improvement. `PROF=1 nvim` records through
`ConfigReady` using debug-tools; startup profiling itself must not run in normal use.

Configured picker actions declare selection-tools availability; LSP edit previews
also declare git-tools. Completion declares its snippet and paired-newline providers.
Image review declares git-tools as an optional enhancement and keeps a plain diff
fallback. These declarations express availability, not initialization order.
`:checkhealth keymap_tools`, `:checkhealth lsp-tools` and `:checkhealth image_tools`
explain missing providers without starting their user interfaces.
