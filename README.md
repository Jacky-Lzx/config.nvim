# Neovim configuration

Personal Neovim configuration for macOS and Linux. It targets Neovim 0.12 and uses
[lazy.nvim](https://github.com/folke/lazy.nvim) for plugins.

## Language profiles

Language support is selected in `lua/config/languages.lua`. The default profiles are:

- `base`: Lua, Bash, JSON, YAML, TOML, KDL
- `web`: HTML, Vue, JavaScript, TypeScript
- `native`: C, C++, CMake, Rust
- `data`: Python
- `writing`: Markdown, LaTeX, Typst

The `optional` profile contains Java, Verilog, Godot, and Matlab. Add `"optional"` to
`enabled_profiles`, or define a smaller profile, to enable them. Only selected language modules
contribute plugins, LSP servers, Mason tools, formatters, linters, and Tree-sitter parsers.

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
- Native: `clang`, `clang-format`, `codelldb`, `cargo`, `rustfmt`
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

Run the side-effect-controlled smoke test with:

```sh
./tests/smoke.sh
```

The syntax/profile pass uses `-u NONE`. The startup pass sets `NVIM_SMOKE_TEST=1`, which disables
project-local configuration and prevents lazy.nvim from cloning or installing missing plugins.
It never invokes the explicit Mason or Tree-sitter installation commands.
