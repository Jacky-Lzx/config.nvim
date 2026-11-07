# Testing

[Quick start](../README.md) · [Architecture](architecture.md)

## Health and testing

Run `:checkhealth config` to validate the selected profiles and language declarations.
Health output is compact: applicable checks produce one success result, while failures
explain their impact and suggest a repair. Functional dependencies are checked by their
owning plugins; inactive optional features do not produce warnings.
`:ConfigInfo` shows the active profiles/workflows, selected language capabilities, currently
enabled LSP servers, live tool paths, and resolved plugin directories/sources/loading states.
`paths.checkout` identifies the actual configuration checkout, including explicit `-u` starts;
`paths.config` remains Neovim's standard config directory. Inspection does not load plugins.

Detailed inspection commands use `Info`, including `:CompletionToolsInfo`,
`:SnippetToolsInfo`, `:LspToolsInfo`, `:ImageInfo`, `:DapToolsInfo`, `:InputToolsInfo`,
`:PairsInfo`, `:NotificationToolsInfo`, `:TaskInfo` and `:WorkspaceInfo`. Specialized commands such as
`:ToolchainPlan` and `:PairsInspect` retain their specific purpose. Internal `status()`
APIs keep their existing names. Health and Info never start services or install tools.

Run the smoke runner with:

```sh
./tests/smoke.sh native         # Offline configuration helpers; isolated plugin data
./tests/smoke.sh integration    # Current defaults and critical configured workflows
./tests/smoke.sh compatibility  # Fixed profiles, optional owners and broader interactions
./tests/smoke.sh acceptance     # Actual local LSPs and installed-plugin fallback
./tests/smoke.sh migration      # Explicit historical snippet parity audit
./tests/smoke.sh all            # All current checks; excludes historical migration parity
./tests/smoke.sh integration --filter tui:tasks --keep
./tests/smoke.sh --check        # Validate script roles and unique case identities
./tests/smoke.sh integration --list
```

Test scripts are grouped by responsibility:

- `tests/native/`: offline checks for configuration policy and helpers.
- `tests/integration/`: configured runtime, startup and explicit acceptance checks.
- `tests/tui/`: real-terminal workflow assertions and their Python drivers.
- `tests/support/`: setup fixtures, action helpers, synchronization and the shared PTY driver.
- `tests/benchmarks/`: startup, first-input and TeX workflow measurements.
- `tests/fixtures/`: retained data, including the historical snippet baseline.

`tests/run.py` remains the executable suite registry behind `tests/smoke.sh`.
Suite membership describes execution requirements independently of script location;
case labels include selection variants so each qualified name is unique. `--filter`
matches those names. Executable cases declare their script files; `tests/roles.json`
records support and explicitly manual scripts. `--check` rejects missing files,
unclassified scripts, conflicting roles and duplicate case names.
The runner and shared PTY driver
resolve unique script names through `tests/support/paths.py`, rejecting missing or
ambiguous names. Direct script invocations use their grouped paths below.
The configured file-tools driver supplies its init file, optional setup script and
`tests/support/file_tools.lua` adapter explicitly. The adapter owns assertions about
this configuration and resolves its declared actions; the external harness owns
filesystem and rendered workflow assertions. It has no dependency on this checkout's
internal test paths or plugin manager.

No argument runs `all`. Use `native` and `integration` during daily configuration
changes, then `compatibility` for changes involving optional owners or their
integration. `acceptance` needs the installed language servers. Remote network
installation and real TeX compilation remain separate explicit commands.

For reusable plugin changes, first run `sh tests/run.sh` in the owning checkout,
then its `integration` suite when changing a shared interface or UI consumer.
Each sibling plugin has `tests/cases.json` as its executable registration list,
`--filter`/`--list`/`--check` for focused work, isolated per-case state, bounded
process lifetimes and retained failure evidence. Its CI executes the same entry
point. `python3 tests/run.py fixtures` is a separate, explicit network operation
for absent pinned sibling checkouts; `--locked` requires those exact clean
revisions. Publish dependency commits before consumer workflows that fetch
them. The shared runner copies are maintained from plugin-tools with
`python3 scripts/sync-test-runner.py --check` or `--write`; each plugin keeps
ownership of its case list and behavior assertions.

The actual personal-startup check uses `lua/config/selection.lua` and current
per-plugin enable flags. It does not restore disabled third-party plugins.
Fixed scenarios live in `tests/support/scenarios.lua`; only the compatibility suite opts
into the optional declarations through `tests/support/full_plugins.lua`. Shared plugin
algorithms belong in the owning plugin's suite; config checks concentrate on
options, activation, mapping ownership and selected cross-plugin workflows.
Generic folding edge cases live in ui-tools' `tests/fold.lua`; configuration checks
retain declared suffix/options, physical keys, saved-session expressions and real
startup/PTY workflows across selected languages. Configured LSP and file-tools
drivers resolve dependency paths through `tests/support/plugins.py`, using the
actual package graph instead of assuming home-directory development checkouts.

`tests/integration/mapping_contracts.lua` audits current `config.bindings` declarations against
effective mode/filetype mappings, including callback/target, expression and prefix
waiting policy. Workflow tests can use a declaration's stable `id` with
`tests/support/actions.lua`; the ID stays beside the owning plugin's key declaration.
Tasks and Wrap/keymap-picker workflows run with both current and deliberately
remapped declarations. File-tree/preview/picker workflows also resolve current
action IDs and run with deliberately remapped keys; dashboard cases verify that
opening a file reuses the startup window and removes placeholder buffers. These
checks execute the resolved file-tools checkout against this configuration's
isolated setup, rather than relying on a fixed home-directory checkout or the
historical plugin manager. Terminal output and the last rendered snapshot are
kept with the case's failure evidence.
The expected task output, window state, focus and editing
results remain independent assertions. Missing actions and overwritten mappings
fail rather than being skipped. Other explicit behavior cases retain their own
reviewable expectations; changing behavior still requires updating those cases.

Each check gets its own cache, state, log, temporary fixtures and copy of the
plugin lockfile. Native checks also isolate data and development-plugin paths.
Inherited Neovim RPC/config/init variables are cleared. Config, temporary and
runtime directories are isolated per case. PTY drivers register process groups
in the case's ledger; timeout and interruption cleanup combines those records
with a descendant snapshot, including children that create new sessions.
An interrupted run retains its partial summary and exits with status 130.
PTY scenario files, environment choices, geometry and input stages are declared in
`tests/support/tui_cases.py`. `tui_protocol.py` reads complete input/resize stages;
the shared terminal driver only starts the editor, dispatches bytes, drains output
and manages its lifetime. Feature assertions remain in each Lua scenario. Folding
UI workflows await editor/window states and an event barrier rather than fixed
delays; negative observation windows in lifecycle checks retain their purpose.
The runner continues after independent failures and reports passed, failed and
skipped checks separately. Failures automatically retain `output.log`, Neovim
logs and state plus `summary.json`; `--keep` also retains successful runs.
Nested PTY workspaces live inside their case directory. `terminal.bin` retains
the raw terminal stream, `terminal.txt` its readable tail, `stage.json` the latest
dispatched/awaited step, and `screen.txt` the final screen on normal/error exit.
Hard-killed editors still leave the terminal stream and stage record. Individual
state snapshots and `result.json` remain beside the case logs. Direct standalone
drivers retain their workspace on failure and print its location.
Environment checks record resolved plugin paths, Git revisions and dirty state.
The runner does not download missing dependencies: install required plugins,
tools and selected parsers explicitly. Selected requirements are checked instead
of assuming the host retains a historical parser inventory.

Setup disables session saving and WakaTime, replaces the desktop clipboard and
stubs external LSP startup. PTY cases still validate actual input and intermediate
UI states. Motion/editing checks observe typed-key consumption before waiting for
the asserted editor state, instead of assuming input finishes within a fixed
number of milliseconds. Image checks use temporary assets and a harmless display
boundary; they validate references, routing, insertion and cancellation without
reading the desktop clipboard.

The optional real LaTeX check requires the configured `texquill` binary, `latexmk`
and a TeX distribution. It uses temporary documents to verify automatic TeX/BibTeX
attachment, save-triggered compilation, PDF/SyncTeX output, manual-build
deduplication, and compiler diagnostic refresh/clearing:

```sh
nvim --clean --headless -i NONE -l tests/integration/latex_build.lua
```

## Debugging and startup performance

`debug-tools.nvim` owns `dd(...)`, `bt()`, and enhanced `vim.print`. It is independent
of the DAP feature. `<leader>tPp` starts/stops Lua profiling (stopping opens the
report); `<leader>tPh` toggles source timing annotations. `:DebugTools show` opens
the last report, Enter jumps to its source, and q closes it. `:DebugTools save`
writes JSON under `stdpath('state')/debug-tools`. `PROF=1 nvim` captures startup
until after `ConfigReady` and saves automatically. Profiling is opt-in, temporarily
disables JIT, and includes hook overhead; it measures the main Lua thread.

`:StartupTime [runs]` is a personal alias for `:DebugToolsStartup [runs]`
(default 10); this command and `:DebugTools startup` use debug-tools' native
`--startuptime` collector, replacing vim-startuptime. Each child has an attached
UI and runs the actual configuration. The report shows mean self/inclusive event
times and total mean/median/min/max; Enter opens source and q closes the report.
These warm sequential runs end at `NVIM STARTED`, separately from the Lua hook
profiler and deferred plugin readiness.

`python3 tests/benchmarks/benchmark_startup.py --output /tmp/nvim-startup.json` repeats fresh
headless startups with isolated state/cache and mocked external LSP/clipboard.
It reports native startup and registration times, and verifies that completion,
snippet and image engines remain uninitialized in an empty editor.

`python3 tests/benchmarks/benchmark_interaction.py --samples 5 --output /tmp/nvim-input.json`
uses fresh real PTYs for empty, Lua, Python and TeX startup, then measures the first
insert, command line or file picker in a separate process. It isolates state/cache,
stubs external LSP and disables AI. Input latency ends after the mode or picker is
ready and a redraw completes; it does not measure display hardware or server replies.
`--baseline /tmp/modules.json` accepts a JSON map of module names to old Lua source
files and interleaves those snapshots with the current configuration. LSP capability
negotiation uses the pure `completion_tools.capabilities` API so the completion core
and UI remain unloaded until input needs them.
Deferring those imports moves work to the first input; assess startup and input
latency together rather than treating a lower startup time alone as an improvement.

`python3 tests/benchmarks/benchmark_workflows.py --directory /tmp/nvim-workflows --rounds 10`
measures real texquill completion in the rendered menu, 200-character PTY bursts,
save completion and fresh native diagnostic refreshes in a multi-file TeX project.
Use `--project /path/to/project --document main.tex` to work on an isolated copy of
an existing manuscript; its source is never edited. AI, grammar checking and
save-time compilation are disabled for this workload. Each output directory must
be new and retains versions, plugin revisions, source snapshots, terminal logs,
raw trials and first/median/p95/max measurements. `--baseline /tmp/modules.json`
compares old module snapshots with current policy in separate processes. Variants
run sequentially, so small differences do not establish a performance improvement.
See [the workflow measurement record](performance/2026-11-07-workflows.md).

`lua/features/files.lua` owns early startup highlighting and large/minified file
guards. Files above 1.5 MiB or averaging over 1000 bytes per line use `bigfile`
filetype and disable completion, Tree-sitter and expensive UI scanning. Save-time
formatting and Codespell also skip protected or currently large/minified buffers,
including unsaved buffers that have grown. Explicit manual formatting remains available.
`lua/features/toggles.lua` owns native option switches and registers read-only
state with keymap-tools; `<leader>th` retains a session-wide inlay-hint preference.

Animations and smooth scrolling are off by default. `<leader>ta` toggles the
ui-tools animation engine; `<leader>tS` toggles smooth Ctrl-d/u/f/b/e/y scrolling.
Enable both for animated scrolling. Existing custom mappings keep ownership.
Obsidian note menus use `vim.ui.select` through selection-tools. Text prompts use
`vim.ui.input` through the existing native input UI. Vault behavior lives in
`obsidian-tools.nvim`; `lua/integrations/obsidian.lua` owns personal mappings and
the completion adapter. The unused `<leader>sp` plugin-spec picker shortcut has
been removed.
