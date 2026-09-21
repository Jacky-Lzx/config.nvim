# Neovim configuration

Personal Neovim configuration for macOS and Linux. It targets Neovim 0.12 and uses
[lazy.nvim](https://github.com/folke/lazy.nvim) for plugins.

## Language profiles

Language support is selected in `lua/config/languages.lua`. The currently enabled profiles are:

- `base`: Lua, Bash, JSON, YAML, TOML, KDL
- `web`: HTML, Vue, JavaScript, TypeScript
- `native`: C, C++, CMake, Rust, Swift
- `data`: Python
- `writing`: Markdown, LaTeX, Typst
- `optional`: Java, Verilog, Godot, Matlab

The `optional` profile is currently enabled by preference. Remove `"optional"` from
`enabled_profiles`, or define a smaller profile, to narrow support. Only selected language modules
contribute plugins, LSP servers, Mason tools, formatters, linters, and Tree-sitter parsers.
Languages without an LSP entry, such as KDL, do not enable an LSP server.

Run `:ConfigToolsInstall` after changing profiles. Tool and parser installation is explicit and
may access the network. Normal startup does not install Mason packages or Tree-sitter parsers.

## Platform configuration

`lua/config/platform.lua` detects macOS and Linux and provides capability-based fallbacks.
The following environment variables override local paths or commands:

- `NVIM_SHELL`
- `NVIM_PYTHON3_HOST_PROG`
- `NVIM_DEBUGPY_PYTHON`
- `NVIM_OPEN_CMD`
- `NVIM_EXTERNAL_TERMINAL`
- `NVIM_SKIM_DISPLAYLINE`
- `NVIM_DEV_PLUGIN_ROOT`
- `NVIM_OBSIDIAN_WORKSPACE`

macOS uses `open` and optionally Skim. Linux uses `xdg-open` and optionally Zathura. Missing
Delta, Kitty, Yazi, Skim, and local development plugins degrade to built-in behavior or disable
their integration.

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

Run the smoke runner with:

```sh
./tests/smoke.sh
```

The script resolves the configuration root and runs from it in a subshell, so it can also be
invoked by path from any working directory. Each suite runs in a separate Neovim process with
`-u NONE -i NONE --noplugin`, isolating test stubs and disabling normal configuration, ShaDa,
and automatic plugin loading. Coverage includes:

- `smoke.lua`: Lua syntax and explicit language profiles without assuming a personal selection;
  includes `lsp_config.lua` once for LSP ordering, capabilities, picker actions, and dependencies.
- `math_conditions.lua`: math detection fallbacks, caching, and invalidation.
- `commands.lua`: title casing across visual selections and explicit ranges.
- `python.lua`: interpreter selection, provider separation, and shell/task argument quoting.
- `rust.lua`: asynchronous Cargo artifact selection, cancellation, and failure handling through DAP.
- `integrations.lua`: Vue server discovery, task defaults, paste mappings, highlight cleanup, and hunk navigation.
- `open_at_cursor.lua`: link extraction from active characterwise, linewise, and blockwise selections.
- `tooling.lua`: formatting controls, completion buffer filtering, lint guards, language tools, and filetypes.
- `lualine_lazy.lua`: deferred task/symbol components, upstream rendering parity, and both provider load orders.
- `mini_diff_lazy.lua`: first-key overlay rendering after asynchronous Git reference loading and subsequent toggling.

Install the configured plugins with `:Lazy sync` before running the full runner. Most regression
tests stub external integrations, but `rust.lua` explicitly loads the installed `nvim-dap` from
`stdpath("data") .. "/lazy/nvim-dap"` and exercises its real evaluator. It does not run Cargo or
start a debug adapter, so Cargo and codelldb are not needed for that test. The Python suite uses
`/bin/sh` and `/usr/bin/printf` to check real `:make` quoting, without running Python.
The statusline tests use installed lualine, Overseer, Trouble, and their rendering dependencies.
The Mini.diff tests require Git and a tracked `init.lua`; they change only an in-memory buffer
and read the reference from the index. Both Lazy key replay and direct first invocation are tested.

The final startup pass loads the real configuration and installed plugins with `-i NONE` and
`NVIM_SMOKE_TEST=1`. This disables ShaDa and project-local configuration and prevents lazy.nvim
from cloning itself or installing missing plugins. The runner never invokes the explicit Mason
or Tree-sitter installation commands. Startup is not fully side-effect-free or sandboxed:
installed plugins and startup hooks still run and may write caches or logs or invoke external
processes.
