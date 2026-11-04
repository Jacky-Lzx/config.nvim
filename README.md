# Neovim configuration

Personal Neovim configuration for macOS and Linux. It targets Neovim 0.12 and uses
[lazy.nvim](https://github.com/folke/lazy.nvim) for plugins.

This repository owns the Lua configuration, plugin specifications, plugin lock,
snippets, queries and editor tests. Nix can supply Neovim and external language
tools without managing plugins. Install this checkout at `~/.config/nvim` for
direct editing, or consume a pinned revision as a non-flake Nix input.

## Plugin versions and Nix deployment

In a writable checkout, `:Lazy update` writes `lazy-lock.json` directly. Review,
test and commit that file with any configuration changes. `NVIM_LAZY_LOCKFILE`
can explicitly select another writable lock for a development session.

For a read-only deployment such as the Nix store, startup seeds or resets
`stdpath("state")/lazy/lazy-lock.json` from the committed lock. Runtime updates
do not change the deployed source. Deploying or rolling back configuration does
not reconcile already installed plugin checkouts; run `:Lazy restore` as well.
Plugins, parsers and managed tools remain runtime installations, outside the Nix
closure. Nix/system executables take priority over toolchain's optional fallback.

The consuming Nix repository pins this repository's commit and deploys its root
as `xdg.configFile."nvim".source`. Publish the tested commit before updating that
input. A machine using a writable checkout should disable ownership of that
directory in Home Manager while retaining its Neovim and language-tool packages.

Run `sh tests/smoke.sh native` for offline tests with isolated plugin data, and
`sh tests/smoke.sh integration` for tests using installed plugins and parsers.
Integration checks also use Python 3 and a terminal PTY to verify actual `VeryLazy`
loading, first-use mappings/commands, and first-save formatting behavior.
To review startup independently, create an isolated XDG config tree with a
`nvim-review` symlink to this checkout and launch with `NVIM_APPNAME=nvim-review`.
That also isolates plugin data, state and cache; prepare those dependencies
explicitly. A bare `-u /path/to/init.lua` is insufficient for every plugin's
runtime-path handling.

## Configuration layout

- `init.lua`: delegates startup to `config.setup()`.
- `lua/config/`: startup composition, platform settings, selection, and lazy.nvim bootstrap.
- `lua/core/`: editor options, general mappings, commands, and autocmds.
- `lua/features/`: native folding, column guide, LSP/diagnostic behavior, and completion source state.
- `lua/plugins/`: lazy.nvim specs, dependencies, loading conditions, and plugin-specific configuration.
- `lua/integrations/`: adapters connecting features to Snacks/Blink and other plugin integrations.
- `lua/languages/`: language metadata and dedicated plugin specs.
- `lua/utils/`: shared helpers for resource paths, platform discovery, and system commands.
- `ftplugin/`: settings needed before runtime ftplugins, such as style and mapping switches.
- `after/ftplugin/`: buffer-local settings; `after/lsp/`: native server overrides.
- `lua/snippets/`, `queries/`, and `lua/overseer/template/`: native discovery paths.

See [the architecture guide](docs/architecture.md) for ownership and lifecycle rules.

`<leader>gf` uses Conform's configured formatters with LSP fallback in all buffers.
LSP attachment adds navigation/refactoring mappings without replacing the shared format key.
`<leader>tf` toggles automatic formatting even before the first save, without loading
Conform. Debugging loads on debugger keys; merely opening C/C++ or Swift does not
initialize DAP. Pairing/snippets load on Insert mode, and optional completion providers
load when used. VimTeX stays available at startup for headless inverse search.

## LSP tools

[lsp-tools.nvim](https://github.com/Jacky-Lzx/lsp-tools.nvim) supplies the code action
picker and previews, replacing code-actions.nvim. `<leader>a` works in Normal and
Visual mode; `<A-a>` works in Insert mode. Enter applies the action, Escape cancels.
Delta renders previews with project-relative hunk headers, with native diff fallback.

`<leader>rn` in LSP-attached buffers prepares the rename, prefills the old name
through the general input-tools API, called automatically by lsp-tools, beside
the source cursor with a left-aligned upper-border title,
and previews the complete workspace edit by file. The title reports affected-file
and edit counts. Enter applies all changes; Escape cancels. Rename uses the same
delta style as code actions. Changes to affected buffers, document versions, or
disk files invalidate the preview and block application; text edits are left unsaved.
The name input starts in Insert mode; Escape enters Normal for Vim motions and
undo/redo. Enter confirms the name before review; Ctrl-C or Normal-mode Escape
cancels the input.

`]r` / `[r` move between the current symbol's references in the current file.
Normal-mode counts work (for example, `3]r`); jumps stop at the ends and add a
jumplist entry. LSP document highlights provide semantic positions, with read/write
highlight groups when supported by the server. lsp-tools owns automatic reference
highlighting, so Snacks.words is disabled. `]]` / `[[` retain native section and
terminal-prompt navigation. Reference navigation itself does not require Snacks.

The configuration prefers the local development checkout through lazy.nvim's
`dev = true`, and falls back to GitHub over SSH when it is absent. Code action options live
under `opts.code_actions`; the public API is `require("lsp-tools").code_action()`.

LSP tools also owns the code-action indicator and linked editing (including
LaTeX environment names with stars and Unicode); nvim-lightbulb and the former
configuration-side linked-editing adapter are no longer needed.

- `<leader>d`: show diagnostics at the cursor in a native floating window; press
  again to enter it. `<A-j>` / `<A-k>` navigate diagnostics and show the same native floats.
- `<leader>gH`: pin hover documentation; `r` refreshes, `f` follows the source cursor,
  `y` copies, and `gx` opens a documentation link. `K` keeps ordinary hover.
- `go` in Normal mode: open the LSP document link, falling back to the existing
  path opener. Visual `go` still opens the selected text. A path-only open keeps
  lsp-tools unloaded when no server offers document links.
- `<leader>g?` / `:LspToolsInfo`: inspect clients, roots, providers and requests.
- `gci` / `gco`: persistent incoming/outgoing call trees; `<leader>gT`: type tree.
  Tab/`l` expands, `h` collapses, `d` switches direction, `p` previews source,
  Enter jumps to the symbol and `g` jumps to a call site.
- `<leader>go`: outline. Both `gi` and `<leader>gr` use the same Snacks references picker.
- `<leader>gd`: live diagnostic overview of all received diagnostics, grouped by
  directory/file. `<LocalLeader>S` cycles all/project/original-buffer scopes;
  `<LocalLeader>d` opens details, `<LocalLeader>a` previews a fix, and
  `<LocalLeader>A` fixes then continues after confirmed diagnostics.
- `<leader>gl`: persistent definitions/references/implementations/type definitions/
  declarations on the right. `<LocalLeader>r` queries the source window's current symbol.
- `<leader>gq` / `<leader>gL`: quickfix / original window's location list. Native
  ordering, current index, visual columns and list history remain canonical.
- `<C-t>` in Snacks picker input (Normal/Insert): import selected items, or all
  filtered items when nothing is selected, into a persistent result snapshot.

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

## Compile commands

With the `tasks` feature enabled, [compile.nvim](https://github.com/Jacky-Lzx/compile.nvim)
provides asynchronous shell commands with output in quickfix. It uses lazy.nvim's
`dev = true` to prefer `NVIM_DEV_PLUGIN_ROOT/compile.nvim`
(default `~/Documents/Github/nvim_plugins/compile.nvim`). When that directory is absent,
lazy.nvim falls back to the GitHub version pinned in `lazy-lock.json`.

- `<leader>mc` / `:Compile`: enter a command, prefilled with the previous command.
- `:Compile cargo build`: run a command directly.
- `<leader>mr` / `:Recompile`: repeat it in its original working directory.
- `<leader>ms` / `:CompileStop`: stop the active compilation.
- `<leader>mo` / `:CompileOpen`: open the most recent compilation output.

Output opens below the editor while the source window keeps focus. In quickfix,
press Enter on a file location to jump there, or use the existing `<leader>J` /
`<leader>K` mappings for the next/previous location. Relative paths resolve from
the working directory at launch. See `:help compile.nvim` for plugin settings.

## Folding

`lua/features/folding.lua` selects native Tree-sitter folding when a parser and folds
query are available, otherwise indentation folding. Diff and special windows retain
their own folding settings. LaTeX uses the same native folding source.

Files initially open all folds; native `zM`, `zR`, `zm`, `zr`, `za`, `zo`, `zc`, `zx`,
and `zX` control them. `2zS` sets the current window's fold level to 2. Folded lines
retain highlighting and show the number of hidden lines after the text, separated
by two spaces.

`zK` previews a closed fold without moving focus; repeat it to enter the preview.
Use `q` or Escape there to close it. Moving the source cursor or entering Insert mode
also closes it. Previews show at most 200 lines in a window up to 100 columns and
20 rows; longer folds are marked in the title. `K` keeps native LSP hover.

## LaTeX

The writing profile loads `tex-tools.nvim` for TeX buffers, using the development
checkout when available and the pinned Git checkout otherwise. Tree-sitter owns
highlighting and folding; tex-tools supplies conceal while preserving math command
spelling (`math_symbols = false`). VimTeX and nvim-texlabconfig are no longer loaded.
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
current/all builds, `<localleader>lg` shows status, and `<localleader>la` toggles
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
by Blink and pairs.nvim.
TeX snippets use tex-tools math context; Markdown retains its own detection.

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
scope dimming, the scrollbar and the startup dashboard. Theme colors live in `lua/config/highlights.lua`.

Existing keys are retained: `<leader><leader>` pulses the current line,
`<leader>Z` toggles Zen, `<leader>z` toggles Zoom, `<leader>tG` toggles indent
guides and `<leader>tD` toggles scope dimming. The column guide uses temporary,
per-window decorations, handles tabs/wide characters and avoids covering text.
Change its `columns` and `char` in the plugin spec.

Set dashboard `layout = "vertical"` for art above the menu or `"horizontal"`
for art on the left. Both layouts fit automatically as the terminal resizes.
The dashboard retains the header art and `f`/`n`/`g`/`r`/`c`/`s`/`L`/`q` actions;
file, grep and recent-file actions use selection-tools. Session restore appears
when auto-session is enabled. Open it manually with `:lua require("ui_tools").dashboard()`.

Snacks dashboard/indent/statuscolumn/Zen/dim are disabled. Snacks still provides its other
features, including scope textobjects. Native folding remains in
`lua/features/folding.lua`. hlslens keeps its match lens and search keys; search
markers and the optional GitTools hunk adapter are provided by ui-tools.
Core yank handling retains clipboard copying, with feedback owned by ui-tools.

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
by `features/treesitter.lua` and the TeX buffer policy. Toolchain now also registers parser
filetype aliases and query predicate compatibility. The nvim-treesitter main plugin is no
longer declared or loaded; Markdown rendering and CodeCompanion depend on toolchain instead.
The independently installed runtime covers all 45 previously installed parser languages,
including Vimdoc, XML, TSX and Svelte. `nvim-treesitter-textobjects` is a separate retained
plugin. `:TSInstallConfigured` submits independent parser tasks. Query data is downloaded
at a fixed nvim-treesitter commit without loading its Lua code; existing legacy checkout
files are retained for rollback but are not required by these managed language bundles.
When migrating an existing installation, old `site/queries` links to that checkout must
be moved outside the runtime path after their languages have managed bundles: Neovim
reads inheritance headers in lower-priority query files too. This machine retains those
links and their manifest under `toolchain-tools/legacy-queries` in the Neovim data directory.
Use `:ToolchainLog` for build logs and `:ConfigToolsInstall` to check/install the current
profile's pinned versions; the old plugin's other `:TS*` commands are no longer registered.

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

## Nix / NixOS editing

The `base` profile enables Nix Tree-sitter highlighting/folding, the `nil_ls` language
server, and `nixfmt` through Conform. Saving formats the buffer when autoformat is
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
`:ConformInfo`, and `:checkhealth config` to inspect the setup.

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
- `NVIM_EXTERNAL_TERMINAL`
- `NVIM_SKIM_DISPLAYLINE`
- `NVIM_DEV_PLUGIN_ROOT`

macOS uses `open` and optionally Skim. Linux uses `xdg-open` and optionally Zathura. Missing
Delta, Kitty, Yazi, and Skim degrade to built-in behavior or disable their integration.

Obsidian workspaces belong to the vault's `.lazy.lua`, in the Obsidian spec's
`opts.workspaces`. The shared spec keeps plugin behavior and mappings, and only enables
Obsidian when the merged options contain a workspace. Start Neovim inside the vault or one
of its subdirectories so lazy.nvim can discover that local spec.

Pairing uses [Jacky-Lzx/pairs.nvim](https://github.com/Jacky-Lzx/pairs.nvim) with lazy.nvim's
`dev = true` and `dev.fallback = true`. It prefers `NVIM_DEV_PLUGIN_ROOT/pairs.nvim`
(default `~/Documents/Github/nvim_plugins/pairs.nvim`); when that directory is absent,
lazy.nvim installs the GitHub version pinned in `lazy-lock.json`. Blink depends on it and
composes Enter after completion confirmation. Use `:checkhealth pairs` for plugin diagnostics.

## Image insertion

Image tools load on image commands, image mappings and picker preview/API calls.
For automatic preview, a lightweight configuration adapter watches Markdown,
LaTeX, Typst and HTML for image-reference candidates, including later edits.
Markdown formula candidates also activate its existing math-preview backend.
Plain documents and disabled automatic preview leave the plugin unloaded;
image-tools still owns syntax exclusions, reference parsing and rendering.
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
- `:ImageInsert` pastes the clipboard; `:ImageInsert path` references an existing file.
  `:ImagePaste` also pastes the clipboard. `:ImagePick` selects existing image references.

Pasted images go into `Figures/` under the current working directory, with names such as
`2026-04-28_16-21-17.avif`. References and previews resolve relative to the current document,
including nested LaTeX files. Typst uses the working directory as its project boundary;
compile nested Typst documents with `typst compile --root . path/to/document.typ`.
Markdown uses `![](path)`, LaTeX uses a figure with 80% line width, caption and label,
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

## Dependencies

Required bootstrap dependencies are Neovim 0.12+, Git, and a usable POSIX shell. A Nerd Font is
recommended for icons. `:ConfigToolsInstall` installs profile-managed tools through the independent toolchain backend, but
some integrations still use system packages:

- General: `fish`, `delta`, `lazygit`, `yazi`, `kitty`
- Web and Markdown: `deno`, `npm`, `gh`, `html_beautify`
- Images: ImageMagick (`magick` or `convert`)
- Native: `clang`, `clang-format`, `codelldb`, `cargo`, `rustfmt`, the Swift toolchain,
  `swiftlint`, and optionally `xcode-build-server` for Xcode projects
- LaTeX: `chktex`, `latexmk`, `tectonic`, and Skim or Zathura
- Optional Verilog: `iverilog` and Verible
- Document conversion tasks: `pandoc`, `xelatex`

The preferred Python provider is `$NVIM_PYTHON3_HOST_PROG`, followed by
`~/.uv/neovim/bin/python3`. If neither exists, Neovim performs its normal provider discovery.
The selected provider must contain the `pynvim` package. Python debugging uses toolchain's isolated debugpy
environment or `$NVIM_DEBUGPY_PYTHON`. JDTLS needs Java 21 or newer;
`$NVIM_JDTLS_JAVA_HOME` overrides its JDK, followed by `$JAVA_HOME` and platform
candidates. macOS also checks existing Homebrew OpenJDK installations without
changing the shell's Java version.

The Vue post-install hook may run `npm install typescript@5` inside the
`vue-language-server` package when its bundled TypeScript 7 is incompatible. This only happens
after an explicit `:ConfigToolsInstall` or `:MasonToolsInstall`.
The task waits for npm, captures its output, and reports failure through the queue; retries
build a fresh version before publication. Intact installations skip their hooks. Language tools
support `post_install_async(package, done, log)` with a neutral `{ name, path, version, resources }`
package record and system-only `optional = true` declarations.
Fish and `html_beautify` are optional: absence appears as `unavailable` instead of a failed install.

## Health and testing

Run `:checkhealth config` to inspect platform capabilities, optional integrations, and tools for
the enabled language profiles.
`:ConfigInfo` shows the active profiles/workflows, selected language capabilities, currently
enabled LSP servers, live tool paths, and resolved plugin directories/sources/loading states.
`paths.checkout` identifies the actual configuration checkout, including explicit `-u` starts;
`paths.config` remains Neovim's standard config directory. Inspection does not load plugins.

Run the smoke runner with:

```sh
./tests/smoke.sh native       # Native behavior and configuration, no installed plugins
./tests/smoke.sh integration  # Installed plugins, parsers, startup and actual input
./tests/smoke.sh              # Both suites; equivalent to ./tests/smoke.sh all
```

The native suite isolates the data and development-plugin directories as well as cache/state,
so it can run on a fresh machine without lazy.nvim, other plugins, or extra parsers installed.
It covers syntax/profile resolution, declaration validation, diagnostic snapshots, core behavior,
clipboard, diagnostics, column guide rendering, completion policy, snippet math, commands,
Python tasks, mocked integrations, links, tooling, and LSP setup contracts.

The integration suite preserves real plugin checks for vault-local options, commenting and
LuaSnip, folding queries, Rust DAP, code actions, image preview, statusline, and Mini.diff.
Image checks also exercise configured insertion templates, cursor positions, working-directory
asset storage, document-relative references, clipboard conversion, menu cancellation, and batch
file selection, using fixture images without accessing the desktop clipboard.
Individual tests run in separate Neovim processes with `-u NONE -i NONE --noplugin`.
Statusline and Mini.diff tests exercise both provider load orders or first-invocation paths.

The syntax/profile pass uses fixed profile selections. The integration startup passes cover
the personal defaults, no languages/workflows, Python with debugging, and writing with tasks. They load the installed
plugins and exercise TeX/Python/Vue filetype hooks, completion, formatting/lint configuration,
DAP configuration, feature isolation, and colorscheme reloads. Actual input checks cover
command-line-first completion loading, paired Enter/Backspace, and development checkout selection.

Tests isolate cache/state/log files, disable session saving and WakaTime, stub external LSP
startup, and set `NVIM_SMOKE_TEST=1` to disable project-local configuration and dependency
installation. They never invoke tool or Tree-sitter installation commands. The full default
pass requires the configured plugins and LaTeX parser to be installed. It verifies local
configuration and plugin setup, not live LSP responses, a running debugger, or PDF compilation.

The optional real LaTeX check requires the configured `texquill` binary, `latexmk`
and a TeX distribution. It uses temporary documents to verify automatic TeX/BibTeX
attachment, save-triggered compilation, PDF/SyncTeX output, manual-build
deduplication, and compiler diagnostic refresh/clearing:

```sh
nvim --clean --headless -i NONE -l tests/latex_build.lua
```

## Notifications and task progress

`notification-tools.nvim` owns `vim.notify`: ordinary notifications appear at the
top right and LSP/background task progress at the bottom right. `<leader>n` and
`<leader>sn` open notification history; `<leader>sN` opens its fuzzy-search picker
with full previews; `<leader>un` dismisses ordinary notifications.
`:NotificationToolsDemo` previews both areas. Successful native file-write status
messages are filtered from notifications/history; errors and other sources remain visible.

The plugin is installed from `Jacky-Lzx/notification-tools.nvim` over SSH.
`dev = true` prefers `NVIM_DEV_PLUGIN_ROOT/notification-tools.nvim`
(default `~/Documents/Github/nvim_plugins/notification-tools.nvim`); lazy.nvim's
`dev.fallback = true` installs the published repository when that checkout is absent.
The lockfile pins the published revision for remote installs. Snacks notifier stays
disabled so only notification-tools owns ordinary notifications; Fidget is no longer configured.

`input-tools.nvim` owns the command line, search/input prompts and native completion
menus. It also prefers the local development checkout through lazy.nvim's shared
`dev.path`. `messages.enabled = true` lets it hand non-interactive messages to
notification-tools after its renderer is ready. Both plugins load at startup;
notifications load first (priority 1100), then input-tools (priority 1000).
Reconfiguring either plugin reacquires the handoff. `<leader>N` also opens
notification history. `:NotificationsPick` uses selection-tools to search complete
messages and details; Enter opens the selected record for reading. Native LSP
show-message notices still use `vim.notify`.

CodeCompanion hooks live
in `integrations.codecompanion_notifications` and create/finish tasks through the
public API; notification-tools itself has no CodeCompanion integration.

Third-party producers can call `require("notification-tools").progress()` and then
use the returned handle's `update`, `finish`, and `cancel` methods. The caller owns
its events and actual cancellation. This configuration disables stale-task expiry
so long-running silent requests remain visible until their producer finishes them.
