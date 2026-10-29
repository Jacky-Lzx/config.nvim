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
Plugins, parsers and Mason tools remain runtime installations, outside the Nix
closure. Nix/system executables take priority over Mason's optional fallback.

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

The configuration prefers the local development checkout through lazy.nvim's
`dev = true`, and falls back to GitHub over SSH when it is absent. Code action options live
under `opts.code_actions`; the public API is `require("lsp-tools").code_action()`.

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
`:ConfigInfo` reports the resolved binary. No Mason package is needed for this server.

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

## Column guide

`lua/features/column_guide.lua` draws `` at display column 121 using native,
temporary decorations. It follows horizontal scrolling independently in each
window, accounts for tabs and wide characters, and avoids covering text.
Special buffers and floating windows do not show the guide. The character uses
the theme's `NonText` highlight. Change `column` and `char` in the module's setup
defaults, or pass these options from `lua/config/init.lua`.

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
may access the network. Normal startup does not install Mason packages or Tree-sitter parsers.

## Adding a language

1. Add `lua/languages/<name>.lua` returning metadata (see `lua/languages/json.lua`).
   Complex languages can use `<name>/init.lua` and `<name>/plugins.lua`.
2. Add the language name to a profile in `lua/config/profiles.lua`.
3. Put server-specific overrides, if needed, in `after/lsp/<server>.lua` and buffer-local
   behavior in `after/ftplugin/<filetype>.lua`. Put switches read by runtime ftplugins
   in `ftplugin/<filetype>.lua` so they are set before the built-in scripts run.
4. Run `./tests/smoke.sh`, restart Neovim, and explicitly install any new tools.

Language `tools` entries distinguish Mason package names from executable names. Omit `mason`
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
NixOS/Home Manager packages. Mason currently only ships `nixfmt` for Linux, so it is
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
system name reported by libuv. `mason_bin` and `debugpy_python` are relative to Neovim's data
directory; user paths support `~`. Restart Neovim after changing these settings.

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

Image tools load on demand for Markdown, LaTeX, Typst and HTML filetypes, image
commands, image mappings, and picker preview/API calls. Empty sessions and other
filetypes leave the plugin unloaded. A `BufReadCmd` trigger also handles image/PDF
files passed at startup, including uppercase extensions, before reading their
binary content. Keep those patterns in sync with custom `buffer.formats`.

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
recommended for icons. `:ConfigToolsInstall` installs profile-managed tools through Mason, but
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
The selected provider must contain the `pynvim` package. Python debugging uses Mason's debugpy
environment or `$NVIM_DEBUGPY_PYTHON`.

The Vue Mason post-install hook may run `npm install typescript@5` inside the
`vue-language-server` package when its bundled TypeScript 7 is incompatible. This only happens
after an explicit `:ConfigToolsInstall` or `:MasonToolsInstall`.

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
installation. They never invoke Mason or Tree-sitter installation commands. The full default
pass requires the configured plugins and LaTeX parser to be installed. It verifies local
configuration and plugin setup, not live LSP responses, a running debugger, or PDF compilation.

The optional real LaTeX check requires the configured `texquill` binary, `latexmk`
and a TeX distribution. It uses temporary documents to verify automatic TeX/BibTeX
attachment, save-triggered compilation, PDF/SyncTeX output, manual-build
deduplication, and compiler diagnostic refresh/clearing:

```sh
nvim --clean --headless -i NONE -l tests/latex_build.lua
```
