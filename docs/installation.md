# Installation

[Quick start](../README.md) · [Architecture](architecture.md)

## Plugin versions and Nix deployment

The manager prefers `NVIM_PLUGIN_TOOLS_PATH`, then the development checkout at
`NVIM_DEV_PLUGIN_ROOT/plugin-tools.nvim`, then its immutable installed revision.
`lua/config/plugin_bootstrap.lua` pins that revision. For a new machine, explicitly run:

```sh
nvim --headless -u NONE -i NONE -l ~/.config/nvim/scripts/install-plugins.lua
```

This installs the pinned manager and plugin lock without starting plugin features.
Language tools and parsers are installed separately with `:ConfigToolsInstall`.
Startup resolves plugin declarations without running Git, checking updates, or
installing missing packages. Ordinary plugins mount at startup; packages declaring
`mount = "on-demand"` wait for a matching `ft` or explicit manager call. Completion,
snippets and images retain their own first-use initialization. There is no
`require()` interception.

TeX tools mount and initialize on the first `tex`/`plaintex` buffer. The TeX
flavor/conceal globals stay in early filetype configuration so native detection
and ftplugins see them in time. Python environment setup waits for a Python
buffer or `:VenvSelect`; session management can mount their shared package earlier
without initializing the Python child. BasedPyright root resolution also ensures
that child is ready before looking up the project environment.

LSP names and filetype hints register at startup. `lsp-tools` prepares the
`nvim-lspconfig` runtime provider just before the first native server config
resolution. An explicit LSP status inspection may also resolve those definitions.
Installation and health still consume the complete selected language declarations.
`:PluginTools explain {id}` exposes mount policy, filetypes, phase and activation
reason; the panel also shows mounting and initialization timings.

Published personal plugins declare their GitHub `source` with `dev = true`.
The shared development policy prefers `NVIM_DEV_PLUGIN_ROOT/<plugin>`; if absent,
the manager selects `NVIM_PLUGIN_ROOT/<plugin>` (default
`stdpath('data')/plugin-tools/<plugin>`) for explicit installation from GitHub.
Startup does not clone repositories automatically.

All GitHub plugin sources use the `owner/repo` shorthand. Set `url_format` in
`lua/config/plugins.lua` to select the shared transport:
`"https://github.com/%s.git"` (the current default) or `"git@github.com:%s.git"`.
This applies to personal and third-party plugin sources; local development
directories keep priority. Existing managed installs and lock entries record the
resolved URL, so changing transport also requires migrating those source records.

All personal plugins have public GitHub sources under `Jacky-Lzx`, including
plugin-tools, debug-tools, editing-tools, file-tools, keymap-tools, motion-tools
and snippet-tools (all `.nvim`). Compatible commits are pinned in the plugin lock;
development overrides keep priority and are excluded from managed operations.
Personal plugin updates target `main`; installs still use the exact locked commit
(a managed Git checkout is detached at that commit). Development checkouts use
their local `main` branches.

Declaring a remote source does not publish local changes. Remote revisions must
provide the APIs used here, including the completion/image bootstrap modules;
synchronize compatible plugin revisions before relying on startup without those
development directories.

`python3 tests/remote_install.py` performs an explicit network acceptance check:
it installs into isolated data/package directories, hides development checkouts,
and verifies minimal/default startup, ordinary Markdown, a selected Obsidian vault,
and completion/image/snippet first-use APIs.
Use `--directory /tmp/nvim-remote-check` to retain the installation for inspection.

Each plugin's `config(ctx)` applies its options and binds personal shortcuts with
`config.bindings.set()`. There is no separate manager bootstrap phase. Plugins
register their own commands and APIs, and keep expensive first-use initialization
inside their implementations; shortcuts call those ordinary commands or APIs.

Specs carry an `origin` label for their configuration module or language; project
contributions use the `.nvim-plugins.lua` path. `:PluginTools explain {id}` shows
declarations and option assignments in merge order, including disabled contributions
and paths replaced by project overrides. Metadata resolution remains side-effect free.

Third-party declarations are grouped by their current enabled state:

- `lua/plugins/third_party/`: WakaTime, render-markdown, Peek and the nvim-lspconfig
  provider loaded as a child of lsp-tools.
- `lua/languages/markdown/plugins.lua`: selects Markdown rendering/preview declarations
  and Obsidian, which is enabled inside a configured vault.
- `lua/plugins/disabled/`: disabled third-party plugins and their language-specific
  options. CodeSnap is retained without a manifest entry.

render-markdown and Peek are children of `markdown-tools.nvim` in the plugin graph,
with their own packages, options and enabled flags. Disabling the parent excludes
both children. They mount and initialize only on the first Markdown buffer.
Rendering remains off until `<leader>tmr`; `:MarkdownPreview` opens Peek after
initialization. Peek requires Deno and its configured build task.

`markdown-tools.nvim` provides structural editing and loads with the first Markdown
buffer from `~/Documents/Github/nvim_plugins/markdown-tools.nvim` (or
`NVIM_DEV_PLUGIN_ROOT`), with a locked GitHub fallback. Its implementation owns
commands and edits; `lua/languages/markdown/tools.lua` owns personal buffer mappings.
The `<localleader>M` group provides `x` checkboxes (also Visual), `i` list item,
`n` renumbering, `o` outline, `t` TOC, `h`/`l` heading promotion/demotion,
`]`/`[` next/previous heading, `f` link,
`a` table alignment, `j`/`k` next/previous cell, `r`/`R` table row insertion/deletion, `c`/`C` column
insertion/deletion, `p` Peek preview, and `e` PDF export. Unoccupied `]h`/`[h`
and `]t`/`[t` navigate headings and cells. Enter and Tab keep their current owners.
Export uses the existing Pandoc/XeLaTeX task with `Heiti SC` on macOS and
`Noto Sans CJK SC` elsewhere; set `NVIM_MARKDOWN_PDF_FONT` to override the font.
Save the file first and enable the tasks feature. Rendering remains under
`<leader>tmr`; Obsidian remains vault-local.

Local plugins keep their workflow directories. Language and feature selections
still control which declarations enter the manifest. Each declaration's `enabled`
field and project selection control activation; the directory itself does not override
them. To restore one plugin, enable its declaration and required dependencies, move its configuration
to `third_party/` or its language module, and update the module referencing it.
There is no global third-party switch. Installed checkouts and lock entries are retained;
theme-tools continues to manage its own theme/icon providers.

External lint checks are owned by `lint-tools.nvim`, configured in
`lua/plugins/coding/lint-tools.lua`. Language definitions supply filetype bindings;
the plugin owns save triggers, process cancellation, parsers and diagnostic
namespaces. Codespell runs when available unless `typos_lsp` is attached.
`:LintToolsInfo` and `:checkhealth lint_tools` explain tool selection and failures.
It prefers the development checkout and otherwise installs its locked GitHub revision,
as do format-tools, markdown-tools and the optional obsidian-tools.

Managed Git packages live under `stdpath("data")/plugin-tools` (override with
`NVIM_PLUGIN_ROOT`); development checkouts remain external. To prepare a new
machine, mount the manager and run its explicit `install()` API with the native
manifest, or use `examples/manage.lua` from its checkout. During migration from
an existing installation, the optional script below copies cached repositories,
ignored build artifacts, and locked revisions into the new independent cache:

```sh
python3 scripts/migrate-plugin-cache.py \
  --source ~/.local/share/nvim/lazy --target ~/.local/share/nvim/plugin-tools \
  --lockfile plugin-tools-lock.json
```

The original cache stays intact for switching to the previous configuration
branch. New plugin operations never adopt arbitrary existing checkouts.

Project/vault configuration uses a nearest `.nvim-plugins.lua` file, read through
`vim.secure.read`. It returns native declarations, for example:

```lua
return { { id = "obsidian-tools.nvim", opts = {
  workspaces = { { name = "Notes", path = "~/Documents/Notes" } },
} } }
```

Declare a shared plugin with `optional = true` to keep its source, options and
configuration dormant until a project selects its ID. The project declaration
above selects the optional Obsidian declaration in `languages/markdown/plugins.lua`
and merges its workspace options with the shared defaults. Unselected optional
plugins and their children do not enter the resolved graph or `runtimepath`, run
setup or native runtime scripts, or participate in installation. Dependencies do
not select them. `start = false` only skips setup and still mounts the runtime.
Project selection is resolved at startup: the first local file/directory argument
is checked before the starting directory. This also covers a new file inside a
vault. Remote URIs and stdin fall back to the starting directory. Trust still uses
`vim.secure.read`. When opening another project, a one-time notice explains that
the original selection remains active; restart Neovim to apply the target project.
`:ConfigInfo` includes the active project file and root.

In a writable checkout, `:PluginTools update` writes `plugin-tools-lock.json` directly. Review,
test and commit that file with any configuration changes. `NVIM_PLUGIN_LOCKFILE`
can explicitly select another writable lock for a development session.

For a read-only deployment such as the Nix store, startup seeds or resets
`stdpath("state")/plugin-tools/plugin-tools-lock.json` from the committed lock. Runtime updates
do not change the deployed source. Deploying or rolling back configuration does
not reconcile already installed plugin checkouts; run `:PluginTools restore` as well.
Plugins, parsers and managed tools remain runtime installations, outside the Nix
closure. Nix/system executables take priority over toolchain's optional fallback.

The consuming Nix repository pins this repository's commit and deploys its root
as `xdg.configFile."nvim".source`. Publish the tested commit before updating that
input. A machine using a writable checkout should disable ownership of that
directory in Home Manager while retaining its Neovim and language-tool packages.

Run `sh tests/smoke.sh native` for offline tests with isolated plugin data, and
`sh tests/smoke.sh integration` for tests using installed plugins and parsers.
Integration checks use Python 3 and real PTYs. Broader optional-plugin and fixed-profile checks run with `sh tests/smoke.sh compatibility`.
To review startup independently, create an isolated XDG config tree with a
`nvim-review` symlink to this checkout and launch with `NVIM_APPNAME=nvim-review`.
That also isolates plugin data, state and cache; prepare those dependencies
explicitly. A bare `-u /path/to/init.lua` is insufficient for every plugin's
runtime-path handling.

## Dependencies

Required bootstrap dependencies are Neovim 0.12+, Git, and a usable POSIX shell. A Nerd Font is
recommended for icons. `:ConfigToolsInstall` installs profile-managed tools through the independent toolchain backend, but
some integrations still use system packages:

- General: `fish`, `delta`, `lazygit`, `kitty`
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
