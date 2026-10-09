# Neovim configuration

Personal Neovim configuration for macOS and Linux. It targets Neovim 0.12 and uses
[lazy.nvim](https://github.com/folke/lazy.nvim) for plugins.

## Configuration layout

- `init.lua`: delegates startup to `config.setup()`.
- `lua/config/`: startup composition, platform settings, selection, and lazy.nvim bootstrap.
- `lua/core/`: editor options, general mappings, commands, and autocmds.
- `lua/features/`: native LSP/diagnostic behavior and completion source state.
- `lua/plugins/`: lazy.nvim specs, dependencies, loading conditions, and plugin-specific configuration.
- `lua/integrations/`: adapters connecting features to Snacks/Blink and other plugin integrations.
- `lua/languages/`: language metadata and dedicated plugin specs.
- `lua/utils/`: shared helpers for resource paths, platform discovery, and system commands.
- `after/ftplugin/`: buffer-local settings; `after/lsp/`: native server overrides.
- `lua/snippets/`, `queries/`, and `lua/overseer/template/`: native discovery paths.

See [the architecture guide](docs/architecture.md) for ownership and lifecycle rules.

`<leader>gf` uses Conform's configured formatters with LSP fallback in all buffers.
LSP attachment adds navigation/refactoring mappings without replacing the shared format key.

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

- `base`: Lua, Bash, JSON, YAML, TOML, KDL
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
   behavior in `after/ftplugin/<filetype>.lua`.
4. Run `./tests/smoke.sh`, restart Neovim, and explicitly install any new tools.

Language `tools` entries distinguish Mason package names from executable names. Omit `mason`
for system-managed tools; use `resolve` for non-PATH tools such as debugpy's Python interpreter.
Installation and health checks consume this same list. Language definitions must not install
anything or register editor behavior while being read; use plugin lifecycle hooks instead.
Declarations are schema-checked, and conflicting definitions of the same tool fail explicitly.
For optional formatter/linter bindings, declare executable requirements in `requires`;
the resolver checks availability rather than freezing it when the language module is loaded.

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

The runner also preserves the command, snippet math, Python/Rust task, integration, link-opening,
tooling, LaTeX highlighting, statusline, and Mini.diff regressions from `dev`. Each runs in a
separate Neovim process with `-u NONE -i NONE --noplugin`. The statusline and Mini.diff tests
exercise the installed plugins and both provider load orders or first-invocation paths.

The syntax/profile pass uses `-u NONE` and fixed profile selections. The startup passes cover
the personal defaults, no languages/workflows, Python with debugging, and writing with tasks. They load the installed
plugins and exercise TeX/Python/Vue filetype hooks, completion, formatting/lint configuration,
DAP configuration, feature isolation, and colorscheme reloads. Actual input checks cover
command-line-first completion loading, paired Enter/Backspace, development checkout selection,
and GitHub fallback when the development directory is absent.

Tests isolate cache/state/log files, disable session saving and WakaTime, stub external LSP
startup, and set `NVIM_SMOKE_TEST=1` to disable project-local configuration and dependency
installation. They never invoke Mason or Tree-sitter installation commands. The full default
pass requires the configured plugins and LaTeX parser to be installed. It verifies local
configuration and plugin setup, not live LSP responses, a running debugger, or PDF compilation.
