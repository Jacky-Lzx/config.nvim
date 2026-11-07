# Workflows

[Quick start](../README.md) · [Architecture](architecture.md)

## LSP tools

`lua/plugins/coding/lsp-tools.lua` maps the selected language profiles to the
plugin's `servers` options. It configures shared completion and file-operation
capabilities at startup and
enables matching servers through lsp-tools when their filetypes are opened
(`server_activation = "filetype"`). Other selected configs remain pending until
needed. `lua/config/server_filetypes.lua` supplies activation hints, so unrelated
native configs are not executed during startup. These hints do not override
native filetypes; the startup tests check that they stay in sync with upstream
and `after/lsp/` configs. Config resolution and full validation occur synchronously
before the first matching server is enabled. Completion's pure capability API is
available before LSP startup; its
interactive setup waits for `InsertEnter`, `CmdlineEnter`, or an explicit completion command.
Requiring the capability API does not initialize completion sources or timers.

See [completion](completion.md) for automatic prose/math source selection, manual
source switches, command-line completion and Copilot, and [native snippets](snippets.md)
for field navigation and personal collections.

nvim-lspconfig is declared as a child of lsp-tools and an explicit dependency.
It keeps its own checkout and lockfile entry, supplies maintained configs, and
has no separate setup or activation hook. Existing `after/lsp/` settings and the
custom `lsp/texquill.lua` config retain native merge
semantics. Tool installation stays with toolchain-tools. `:checkhealth lsp-tools`
and `:LspToolsInfo` show selected server configuration and attachment state.

The Lua profile enables lsp-tools' native LuaLS library discovery, replacing
lazydev.nvim. Literal `require` calls and module annotations load only the needed
plugin libraries. `vim.uv` and `debug_tools` retain their conditional type rules;
local and installed plugin directories supply source paths without executing
plugins. `:LspToolsLua` lists libraries and `:LspToolsLua refresh` rescans paths.
This configuration explicitly supplements projects with `.luarc.json`, preserving
the previous policy while leaving those project files untouched.

[lsp-tools.nvim](https://github.com/Jacky-Lzx/lsp-tools.nvim) supplies the code action
picker and previews, replacing code-actions.nvim. `<leader>a` works in Normal and
Visual mode; `<A-a>` works in Insert mode. Enter applies the action, Escape cancels.
The configured backend renders native diff previews with project-relative file headers.

`<leader>rn` in LSP-attached buffers prepares the rename, prefills the old name
through the general input-tools API, called automatically by lsp-tools, beside
the source cursor with a left-aligned upper-border title,
and previews the complete workspace edit by file. The title reports affected-file
and edit counts. Enter applies all changes; Escape cancels. Rename uses the same
native diff backend as code actions. Changes to affected buffers, document versions, or
disk files invalidate the preview and block application; text edits are left unsaved.
The name input starts in Insert mode; Escape enters Normal for Vim motions and
undo/redo. Enter confirms the name before review; Ctrl-C or Normal-mode Escape
cancels the input.

`]r` / `[r` move between the current symbol's references in the current file.
Normal-mode counts work (for example, `3]r`); jumps stop at the ends and add a
jumplist entry. LSP document highlights provide semantic positions, with read/write
highlight groups when supported by the server. lsp-tools owns automatic reference
highlighting; the former Snacks.words provider is removed. `]]` / `[[` retain native section and
terminal-prompt navigation. Reference navigation itself does not require Snacks.

The configuration prefers the local development checkout through plugin-tools'
`dev = true`, and falls back to GitHub using the shared transport when it is absent. Code action options live
under `opts.code_actions`; the public API is `require("lsp-tools").code_action()`.

LSP tools also owns the code-action indicator and linked editing (including
LaTeX environment names with stars and Unicode); nvim-lightbulb and the former
configuration-side linked-editing adapter are no longer needed.

- `<leader>d`: show diagnostics at the cursor in a native floating window; press
  again to enter it. `<A-j>` / `<A-k>` navigate diagnostics and show the same native floats.
- `<leader>gH`: pin hover documentation; `r` refreshes, `f` follows the source cursor,
  `y` copies, and `gx` opens a documentation link. `K` keeps ordinary hover.
- `go` in Normal mode: open the LSP document link, falling back to file-tools'
  system path opener. Visual `go` opens the selected text. A path-only open keeps
  file-tools as the fallback when no server offers document links.
- `<leader>g?` / `:LspToolsInfo`: inspect clients, roots, providers and requests.
- `gci` / `gco`: persistent incoming/outgoing call trees; `<leader>gT`: type tree.
  Tab/`l` expands, `h` collapses, `d` switches direction, `p` previews source,
  Enter jumps to the symbol and `g` jumps to a call site.
- `<leader>two`: outline. Both `gi` and `<leader>gr` use the same lsp-tools references picker.
- `<leader>twd`: live diagnostic overview of all received diagnostics, grouped by
  directory/file. `<LocalLeader>S` cycles all/project/original-buffer scopes;
  `<LocalLeader>d` opens details, `<LocalLeader>a` previews a fix, and
  `<LocalLeader>A` fixes then continues after confirmed diagnostics.
- `<leader>twl`: persistent definitions/references/implementations/type definitions/
  declarations on the right. `<LocalLeader>r` queries the source window's current symbol.
- `<leader>twq` / `<leader>twc`: quickfix / original window's location list. Native
  ordering, current index, visual columns and list history remain canonical.
- `<C-t>` opens the selected picker item in a tab; `<C-q>` and `<C-l>` export
  marked items, or the filtered results, to quickfix and the location list.

Trouble is replaced by lsp-tools. Result lists keep source focus when opened;
Enter jumps; groups use native Neovim folds: `za`, `zc`/`zo`, `zM`/`zR`,
`zm`/`zr`, and `zj`/`zk` work directly. Fold states survive live diagnostics and
reopening. Result actions use `<LocalLeader>` (Space in this configuration):
`o` jumps while keeping list focus, `p` previews,
`f` filters, `e` filters errors, `F` pins, `Q` exports to quickfix, and `?` shows
only lsp-tools bindings. Escape or `<LocalLeader>q` closes the result window.
Native `gg/G`, word/character motions, `/` and `?` search, yank and macro commands
remain available. Lists survive source-buffer closure. Each source loads on its
first entry; picker configuration and LSP attachment keep the result engine deferred.

Other persistent panels use `q` / Escape to close. Server-dependent features are
available only when a client advertises the corresponding methods.

## Debugging

With `features.debugging = true`, `dap-tools.nvim` owns debug configuration and an
independent panel; `nvim-dap` remains the protocol/session backend. The backend and
panel load on first action. There is no dependency on nvim-dap-view or nvim-dap-ui.
Python, C/C++, Rust and Swift opt into plugin presets through their language
declarations. toolchain-tools installs adapters; Python shares the selected project
interpreter/environment with LSP and tasks. Rust builds asynchronously and selects
an executable from Cargo's emitted artifacts.

`F5` launches/continues; `F6`/`F7`/`F8` step over/into/out; `F9` pauses; `F10`
terminates. `Space b` toggles a breakpoint, `Space B` prompts for its condition,
`Space D b` creates a logpoint, `Space D c` chooses a configuration and `Space D a`
launches with quoted arguments. `Space t w a` toggles the panel.

In the panel, `1`–`5` select scopes, stack, watches, breakpoints and output. Enter
expands/jumps, `a` adds a watch, `d` deletes a watch/breakpoint, `s` switches sessions,
and `q` hides the panel without ending debugging. Automatic opening preserves source
focus. Use `:DapToolsRepl` for interactive evaluation and `:checkhealth dap_tools`
for adapter checks. See the plugin README for custom launch/attach configurations.

## Tasks and terminals

With `features.tasks = true`, `task-tools.nvim` (preferring the checkout at
`NVIM_DEV_PLUGIN_ROOT/task-tools.nvim`, with GitHub as the managed fallback)
owns builds, project task discovery, save watchers and interactive terminals.
It replaces compile.nvim, Overseer and Snacks terminal. With the tasks feature
disabled, task commands and the `<leader>tws` shell mapping are not registered.

- `<leader>mc`: enter a manual build command (initially `make`).
- `<leader>mr/ms/mo`: rerun/stop/show that manual build, even after other tasks or terminals run.
- `<leader>mq`: export the manual build's current output into quickfix.
- `<F17>` / `<leader>or` / `:TaskRun`: select a discovered task.
- `<leader>twt`: toggle the task list; Enter opens output, r reruns, s stops, c exports quickfix.
- `<leader>oa`: run the current Python/C/C++ file with arguments; C/C++ also prompts for an executable.
- `<leader>os/oo/oq`: stop/show/export the latest task, including non-build tasks.
- `<leader>tws` (Normal mode): toggle a persistent shell for the current directory.
  From a running terminal, use `Ctrl-\ Ctrl-n` first; terminal typing has no Space prefix mapping.

Manual build output streams below the editor without taking focus. Enter jumps
to a compiler location. Quickfix is an explicit snapshot (`:TaskQuickfix [id]`,
output `gq`, or the mappings above); `<leader>J/K` navigate exported locations.
New task output never overwrites the current quickfix list.

Terminals default to centered rounded floats (90% width/height) and preserve their
process while hidden. `Ctrl-]` enters terminal normal mode, then q hides the window.
Configure position/size/border in `lua/plugins/tasks/task-tools.lua`. Python uses
the live `languages.python.interpreter` provider. Argument input supports quotes,
escaped spaces and empty quoted arguments, without shell expansion. Files run from
disk; buffers are not automatically written. Pandoc PDF tasks retain the CJK font.

workspace-tools stores task definitions under `stdpath('state')/task-tools/sessions`,
keyed by workspace ID. Restoring a workspace registers choices without running any
commands or watchers; deleting a workspace deletes its task bundle. Task panels are
closed before saving, and native terminals remain excluded from sessionoptions.
Process state, output, stdin and environment overrides are not persisted.
See `:help task-tools` for project JSON, watch options and the Lua API.

## Workspaces

`workspace-tools.nvim` owns workspace persistence and history search when
`features.sessions` is enabled. It prefers the checkout under `NVIM_DEV_PLUGIN_ROOT`
and selects the GitHub repository for managed installation when that checkout is absent.

| Key | Action |
| --- | --- |
| `<leader>pw` | Save current workspace (`:WorkspaceSave [name]`) |
| `<leader>ps` | Restore current workspace (`:WorkspaceRestore [name-or-id]`) |
| `<leader>pS` | Fuzzy-search history (`:WorkspaceSearch [query]`) |
| `<leader>pD` | Delete a saved workspace, with confirmation |

The dashboard's `s` action restores the current workspace. Search uses
selection-tools. Workspace files, tabs, splits, views and folds are saved on
exit; startup restoration remains disabled. Home, `~/Projects`, `~/Downloads`
and `/` are excluded from automatic operations. Modified buffers must be saved
or discarded before restoring. `:WorkspaceStop` pauses exit saving and
`:WorkspaceStart` resumes it. Named workspaces can share the same directory.

Records live under `stdpath('state')/workspace-tools`; task definition hooks use
the stable workspace ID. `:WorkspaceLast` restores the most recently used record.
See `:help workspace-tools` for the API, save guards and storage behavior.

## Folding

`ui-tools.nvim` selects native Tree-sitter folding when a parser and folds
query are available, otherwise indentation folding. Personal options live in
`lua/plugins/ui/ui-tools.lua`. `lua/features/folding.lua` preserves the old module
path for fold expressions stored in existing sessions. Diff and special windows retain
their own folding settings. LaTeX uses the same native folding source.

Files initially open all folds; native `zM`, `zR`, `zm`, `zr`, `za`, `zo`, `zc`, `zx`,
and `zX` control them. `2zS` sets the current window's fold level to 2. Folded lines
retain highlighting and show the number of hidden lines after the text, separated
by two spaces.

`zK` previews a closed fold without moving focus; repeat it to enter the preview.
Use `q` or Escape there to close it. Moving the source cursor or entering Insert mode
also closes it. Previews show at most 200 lines in a window up to 100 columns and
20 rows; longer folds are marked in the title. `K` keeps native LSP hover.

## Writing diagnostics

The writing profile uses **LTeX+** (`ltex_plus`) for English grammar in Markdown,
plain text and TeX, alongside Marksman and TeXquill for document structure.
Checks run when a document is opened or saved; picky style rules are disabled.
`typos_lsp` retains spelling checks, so LTeX+'s English spelling rule is disabled.
Use `<leader>a` on a diagnostic for replacement suggestions.

`after/lsp/ltex_plus.lua` owns language and grammar settings. The default is
`en-US`; document language overrides can use LTeX+ magic comments, for example
`<!-- LTeX: language=zh-CN -->` in Markdown or `% LTeX: language=zh-CN` in TeX.
toolchain-tools' registry supplies official, checksum-pinned LTeX+ releases
with a bundled Java runtime. `:ConfigToolsInstall` installs the managed version
recorded in `toolchain-lock.json`.

## LaTeX

The writing profile loads `tex-tools.nvim` for TeX buffers, using the development
checkout when available and the pinned Git checkout otherwise. Tree-sitter owns
highlighting and folding; tex-tools supplies conceal while preserving math command
spelling (`math_symbols = false`). VimTeX and nvim-texlabconfig are no longer loaded.
LaTeX uses the same Tree-sitter startup logic as other languages.
theme-tools owns TeX semantic-token colors; attaching another TeX buffer does not
rewrite global highlight groups.
The parser and Neovim queries both come from the pinned `Jacky-Lzx/tree-sitter-latex`
fork in `lua/languages/latex/plugins.lua`. Its bundled queries own delimiter
compilation and math/path highlight priorities; no runtime query rewriting or
capture disabling is needed. `:TSInstallConfigured` installs the pinned artifacts;
restart Neovim afterwards to activate them.

**TeXquill** provides completion, hover, navigation, renaming, semantic
highlighting and pull diagnostics for TeX and BibTeX. Texlab is not enabled on this branch.

`lsp/texquill.lua` starts the installed `texquill` executable from PATH with `--stdio`.
Ensure the installation directory (for example, `~/.cargo/bin`) is on Neovim's PATH.
Set `NVIM_TEXQUILL` to use another executable, including a local development build.
After updating the server, restart Neovim (or the LSP client).
`:ConfigInfo` reports the resolved binary. No managed package is needed for this server.

The default compiler is **latexmk**, with `build.onSave = true`. The server honors
the project `.latexmkrc` output directory, falling back to `build/texquill/` beside
the main document. `<localleader>ll` and `<leader>lb` save
and build without queuing a duplicate save build; `<localleader>lk/lK` cancels the
current/all builds, `<localleader>lg` shows status, and `<leader>txa` toggles
build on save. `<localleader>lq` opens the compiler log, `lo` shows the latest output
summary, and `le` opens native diagnostics. Compiler errors refresh automatically
and disappear after correction. The diagnostic refresh handler also updates open
buffers when workspace pull diagnostics are enabled.

Use `% !TeX root = ../main.tex` in child files and `% !TeX program = xelatex` in the
main file to select XeLaTeX. Server options live in `lsp/texquill.lua`; keep
`init_options.build` and `settings.latex.build` consistent. `<localleader>lV` opens
the PDF; `lv` performs forward search with Skim or Zathura after a successful build.

Tex-tools uses `lsp = "texquill"` for build/status, compiler switching, main
selection, cleanup, outline and PDF integration, alongside structural editing,
conceal and navigation. Compiler profiles use the server's native settings:
`latexmk` and `tectonic` use default arguments, while `xelatex` selects latexmk
with `engine = "xelatex"`. The server owns argument generation and artifact paths.
The existing build/status/log/PDF shortcuts in `lua/languages/latex/lsp.lua`
remain available. Tex-tools handles Skim startup and positioning;
`viewer.focus = false` keeps focus in Neovim.

Text objects follow tex-tools defaults: `ae/ie` environment, `ac/ic` command,
`aa/ia` argument, `a$/i$` math, `ad/id` math brackets, `ai/ii` item, `aP/iP` section,
and `at/it` cell. Structural edits use tex-tools defaults: `<localleader>lcr/lcd/lcs`
rename/unwrap/surround commands, `ler/let/les/led` edit environments, and
`ldc/ldd/ldt/ldm` edit or match math brackets. Insert `]]` closes the nearest
missing marker. Normal `]]/[[` navigate sections, `]e/[e` environments, `]m/[m`
math, `]i/[i` items and `]t/[t` table cells.
`<localleader>li` shows project information; use `:TexToolsInsertItem` or
`<Plug>(TexToolsInsertItem)` to insert an item. Space-prefixed shortcuts stay
out of Insert mode so typing Space stays immediate; Enter remains composed
by completion-tools and pairs.nvim.
TeX snippets use tex-tools math context; Markdown retains its own detection.

All filetypes use snippet-tools. Native collections include Lua,
Python, Rust, Typst, Verilog/SystemVerilog, Markdown, TeX and global date/time/TODO
snippets. `<A-l>`/`<A-h>` navigate fields, `<A-j>`/`<A-k>` cycle choices and `<A-c>`
opens the choice picker. Visual backtick captures text for the next snippet.
`:SnippetToolsReload` reloads definitions; `:SnippetToolsInfo` shows the active session.
The 154 migrated definitions are checked against a frozen pre-migration baseline;
LuaSnip and its engine-switch commands have been removed.

Project snippet directories can be declared in the trusted `.nvim-plugins.lua`:

```lua
return {
  { id = "snippet-tools.nvim", opts = { project = { paths = { ".nvim/snippets" } } } },
}
```

The configuration supplies the root from that project file, so paths resolve the
same way when starting in a subdirectory or changing cwd. Put native definition
lists in `.nvim/snippets/<filetype>.lua` and `all.lua`. Global collections remain
available; project entries win equal-priority conflicts and apply only to named
buffers inside that project. Filetype inheritance still applies.

Project Lua snippet files use Neovim's content-based file trust. When prompted,
view and inspect the file, run `:trust`, return to the project buffer and run
`:SnippetToolsReload`. Modified files require trust again; changing definitions
does not require restarting Neovim. Reload discovers new files, removes deleted
definitions, retains the previous valid collection on errors, and preserves active
snippet fields. `:SnippetToolsInfo` includes source paths, scope, trust, errors,
and the currently matching definition. No project code is executed merely because
a snippet directory exists; the trusted project declaration must enable it.

VimTeX-only selected-region compilation, structural `%`, environment/math/section
end motions, frame/comment motions, `ds$`, Visual fraction/size toggles, `tsb`,
`tsD`, Insert `<F7>`, package-documentation `K`, cache/reload and input-map menus
have no direct replacement and their old mappings were removed. Native `%` and
LSP `K` remain available. Use `:TexToolsConvertMath` for explicit math conversions;
row/column editing and section promotion/demotion are available as TexTools commands.

## Editor UI helpers

`lua/plugins/ui/ui-tools.lua` loads the local ui-tools.nvim checkout through
`utils.platform.dev_plugin_root()`. It owns indentation/chunk guides, the status
column, the column-121 `` guide, transient line/yank highlighting, Zen/Zoom,
scope dimming, the scrollbar, inline color previews, TODO annotations and the startup
dashboard. Theme colors live in `lua/integrations/theme.lua`.

Color literals use inline `■` swatches. TODO/FIX/NOTE and related tags use
syntax-aware badges, description colors and gutter signs. Configure `colors` and
`todo` in the ui-tools spec; their previous nvim-highlight-colors and
todo-comments.nvim renderers are no longer loaded. Project TODO searches remain
on `<leader>st` and `<leader>sT` through selection-tools.

`<leader><leader>` pulses the current line,
`<leader>tuz` toggles Zen, `<leader>tum` toggles Zoom, `<leader>tui` toggles indent
guides and `<leader>tud` toggles scope dimming. The column guide uses temporary,
per-window decorations, handles tabs/wide characters and avoids covering text.
Change its `columns` and `char` in the plugin spec.

Set dashboard `layout = "vertical"` for art above the menu or `"horizontal"`
for art on the left. Both layouts fit automatically as the terminal resizes.
The dashboard retains the header art and `f`/`n`/`g`/`r`/`c`/`s`/`L`/`q` actions;
file, grep and recent-file actions use selection-tools. Session restore appears
when the `sessions` feature enables workspace-tools. Open it manually with `:lua require("ui_tools").dashboard()`.

Snacks is no longer loaded. ui-tools owns visual helpers, editing-tools owns
indentation textobjects, and motion-tools owns indentation jumps. Folding behavior
and lifecycle belong to ui-tools; `lua/features/folding.lua` preserves old session
expressions. motion-tools provides the match lens and search keys;
search markers and the optional GitTools hunk adapter are provided by ui-tools.
Core yank handling retains clipboard copying, with feedback owned by ui-tools.

## Search and navigation

`lua/plugins/navigation/file-tools.lua` loads the local `file-tools.nvim` checkout
from `NVIM_DEV_PLUGIN_ROOT` and uses `theme-tools.nvim` for shared tree colors.
`<leader>twf` toggles the tree, `<leader>E` reveals the current file, and `<leader>cw`
opens the working directory. The tree's `a/r/d` create, move/rename and confirm
permanent deletion; `y/x/p` copy, cut and paste. `h/l` fold or open directories.
`:FileTools` exposes the same tree and file-operation APIs. The LSP configuration
merges file-operation capabilities with completion capabilities before enabling
servers. nvim-tree, its separate LSP file-operation adapter, and Yazi are removed.
Sidebar bufferline spacing and progress-notification avoidance use `file-tools`.

File-tools also owns `go` path/URL opening through `open_at_cursor()` and
`open_external(target)`. Relative paths are tried beside the current buffer,
then in cwd, then at the Git root. The configuration supplies its platform opener,
including the `NVIM_OPEN_CMD` override; `utils/open.lua` is no longer needed.

`:FileToolsRead[!] [path]` and `:FileToolsWrite [path]` provide explicit sudo reads
and writes, replacing vim-suda. Existing `:SudaRead` / `:SudaWrite` commands forward
to these APIs. Authentication uses a terminal split when needed; closing it
cancels the operation. Dirty reads require `!`, and edits made during authentication
are guarded. Writes preserve native encoding, BOM and newline options, but are
in-place operations without backups.

`lua/plugins/navigation/motion-tools.lua` loads the local motion-tools.nvim checkout
from `utils.platform.dev_plugin_root()`. It replaces Flash, hlslens and mini.bracketed;
search feedback is ready at startup, including the first native `/` or `?` search.

`<leader>f` searches literal text: type a query, Enter/Tab, then a displayed label.
`<leader>j` and `<leader>k` label nonblank line starts. `<leader>F` chooses an ancestor
syntax node in Normal mode; in Visual/operator mode it searches text and selects
the matching syntax node. `<C-f>` in `/` or `?` chooses a label for that search.
Escape cancels and restores the source view. Normal jumps can cross windows;
Visual and operator jumps stay in their source window.

`n/N/*/#/g*/g#` retain native search behavior and show a match counter. Bracket
keys navigate diagnostics (`d`), quickfix/location (`q/l`), jumplist (`j`) and
syntax boundaries (`t`); uppercase suffixes seek the first/last target. `[i`/`]i`
seek more indentation, `[o`/`]o` less. `[b`/`]b` remain owned by ui-tools and follow
bufferline order; `[B`/`]B` select the first/last listed buffer.

## Nix / NixOS editing

The `base` profile enables Nix Tree-sitter highlighting/folding, the `nil_ls` language
server, and `nixfmt` through format-tools.nvim. Saving formats the buffer when autoformat is
enabled; `<leader>gf` formats manually. Existing LSP mappings provide completion,
hover, definitions, references, renaming, and code actions.

Run `:ConfigToolsInstall` to install the parser and `nil` (building it requires Cargo and Nix). Install
`nixfmt` separately: `brew install nixfmt` on macOS, or add `nil` and `nixfmt` to your
NixOS/Home Manager packages. The configuration uses a system `nixfmt`, which is
registered as a system tool.

Basic diagnostics, local completion, navigation, and formatting work without Nix.
Evaluating flake inputs and NixOS options requires a working `nix` installation with
flakes enabled and locally available inputs. `nil` recognizes the `nixpkgs` flake
input for NixOS options. Automatic input downloading is disabled; prepare inputs
explicitly with `nix flake archive` from the project directory. Use `:LspInfo`,
`:FormatToolsInfo`, and `:checkhealth config` to inspect the setup.

## Image insertion

Obsidian vault mappings attach once per buffer and workspace. Re-entering a note
preserves temporary mapping overrides; renaming across vault boundaries or
reconfiguring the integration updates the owned mappings.

The automatic image/formula switch is a session preference. Disabling it in any
filetype also updates an already-loaded TeX controller; a later first TeX buffer
inherits the same preference. Explicit setters are idempotent and preserve cold
rendering/compiler backends. Per-type TeX preview options remain separate from
the master automatic-preview gate.

Image tools load on image commands, image mappings and picker preview/API calls.
For automatic preview, image-tools' lightweight bootstrap watches document
references and literal local image paths in filetypes without an adapter,
including later edits and cursor movement. Quoted paths can contain spaces;
relative paths resolve against the document directory. Set `path_preview = false`
in image-tools options to disable the generic fallback. Existing document adapters
retain their syntax exclusions. Plain documents without candidates and disabled
automatic preview leave the display backend unloaded.

tex-tools owns LaTeX image/formula selection, graphicspath resolution and formula
compilation, calling image-tools only for display. `<leader>si` uses its unified
`preview()` API in LaTeX buffers; other filetypes use image-tools lookup.
Formula previews request the image backend only after compilation succeeds.
The shared preview/toggle mappings do not initialize the image backend merely
to inspect a formula or turn automatic preview off. A `BufReadCmd` trigger
handles image/PDF files passed at startup, including uppercase extensions,
before reading their binary content. Keep those patterns in sync with custom
`buffer.formats`.

`lua/plugins/navigation/images.lua` uses the local `image-tools.nvim` checkout and preserves
these behaviors from the former `image-insert.nvim` configuration:

- `<leader>pI` / `<leader>PI`: paste on the next / previous line.
- `<leader>pi` / `<leader>Pi`: paste after / before the cursor.
- `<leader>pC`: choose PNG, JPEG, WebP, AVIF, or original PNG, then edit the filename.
  The menu only offers formats supported by the document.
- `<leader>pc`: select one or more existing images and insert references on the next line;
  the source files are not copied. `<leader>pf` explicitly imports a copy instead.
- `:ImagePaste` pastes the clipboard; `:ImageInsert! path` references an existing file.
  `:ImageInsert [path]` imports a file using the plugin's configured insertion mode.
  `:ImagePick` selects existing image references.

Pasted images go into `Figures/` under the current working directory, with names such as
`2026-04-28_16-21-17.avif`. References and previews resolve relative to the current document,
including nested LaTeX files. Typst uses the working directory as its project boundary;
compile nested Typst documents with `typst compile --root . path/to/document.typ`.
Markdown uses `![](../path)`, LaTeX uses a figure with 80% line width, caption and label,
Typst uses a figure with 80% width and caption, and HTML uses
`<img src="path" alt="" />`. The cursor enters insert mode inside the description/caption.
On macOS, `pbctl` is preferred when installed; otherwise the plugin selects an available backend.

Some differences are intentional: LaTeX and Typst paste PNG by default because the built-in
adapters reject AVIF for compiler compatibility. Markdown and HTML retain AVIF by default. Unsupported file formats are
filtered from the picker. JPEG/AVIF choices perform actual conversion instead of merely changing
a PNG filename's extension. Filenames are single basenames, collisions receive a numeric suffix,
and insertion requires a named, modifiable document. Markdown URL characters and HTML/Typst
string characters are escaped. Filename input is asynchronous and prefilled with the timestamp;
accept the default with Enter, or cancel with Escape. In a batch, the first image's description
receives the cursor. These validation and editing rules come from `image-tools.nvim` rather
than the configuration. Image conversion needs `magick`; clipboard capture needs an available
platform backend such as `pbctl` or `pngpaste` on macOS.

## Notifications and task progress

`notification-tools.nvim` owns `vim.notify`: ordinary notifications appear at the
top right and LSP/background task progress at the bottom right. `<leader>n` and
`<leader>sn` open notification history; `<leader>sN` opens its fuzzy-search picker
with full previews; `<leader>un` dismisses ordinary notifications.
`:NotificationToolsDemo` previews both areas. Successful native file-write status
messages are filtered from notifications/history; errors and other sources remain visible.

The plugin is installed from `Jacky-Lzx/notification-tools.nvim` using the shared transport.
`dev = true` prefers `NVIM_DEV_PLUGIN_ROOT/notification-tools.nvim`
(default `~/Documents/Github/nvim_plugins/notification-tools.nvim`); plugin-tools'
`dev.fallback = true` selects the published repository when that checkout is absent.
The lockfile pins the published revision for remote installs. Snacks notifier stays
disabled so only notification-tools owns ordinary notifications; Fidget is no longer configured.

`input-tools.nvim` owns the command line, search/input prompts and native completion
menus. It also prefers the local development checkout through plugin-tools' shared
`dev.path`. `messages.enabled = true` lets it hand non-interactive messages to
notification-tools after its renderer is ready. Both plugins load at startup;
notifications register before input-tools in the explicit manifest order.
Reconfiguring either plugin reacquires the handoff. `<leader>N` also opens
notification history. `:NotificationsPick` uses selection-tools to search complete
messages and details; Enter opens the selected record for reading. Native LSP
show-message notices still use `vim.notify`.

Copilot completion remains controlled by the `ai` feature.

Third-party producers can call `require("notification-tools").progress()` and then
use the returned handle's `update`, `finish`, and `cancel` methods. The caller owns
its events and actual cancellation. This configuration disables stale-task expiry
so long-running silent requests remain visible until their producer finishes them.

Textobject queries for the configured programming and document languages are
bundled in editing-tools. nvim-treesitter-textobjects is no longer a dependency;
query provenance and the pinned upstream license are retained in the plugin.
Parser installation and versions remain owned by toolchain-tools.

## Python project environments

`:VenvSelect` / `<leader>cv` now use workspace-tools' Python environment module.
Select a discovered environment, enter an executable/environment path, or choose
Automatic/System. `:VenvSelect /path/to/.venv` selects directly; `:VenvSelect!`
clears the project override. Choices are stored per project under
`stdpath('state')/workspace-tools/python`; missing or corrupt selections fall back
to local `.venv`, `venv`, `env`, then inherited environment/PATH discovery.

The Python profile makes the workspace-tools runtime available independently of
the sessions feature. With sessions disabled, environment selection does not
initialize workspace saving/restoring. BasedPyright uses the same project root
and receives interpreter updates without restarting other clients. Tasks and DAP
share `languages.python.interpreter`; child processes receive the selected PATH
and environment variables without changing Neovim's global environment. `:make`
continues to resolve the live interpreter when invoked. Environment creation and
Poetry/Conda management remain external.
