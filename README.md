# Neovim configuration

Personal Neovim configuration for macOS and Linux, using published plugins from
`Jacky-Lzx` and exact revisions in `plugin-tools-lock.json`.

## Features

- Native LSP, completion, snippets and language-specific editing workflows.
- Search, file operations, tasks, debugging and named workspace sessions.
- Optional Markdown, Obsidian, LaTeX and terminal image workflows.
- Explicit installation, local development overrides and pinned Nix deployment.

## Requirements

Neovim **0.12+** and Git. Install external language tools and parsers separately.
Python 3 is required for the local test runner. Feature-specific requirements are
listed in [the installation guide](docs/installation.md#dependencies).

## Installation

Place this checkout at `~/.config/nvim`, then install the locked plugins:

```sh
git clone --branch feat/plugin-tools-migration \
  https://github.com/Jacky-Lzx/config.nvim.git ~/.config/nvim
nvim --headless -u NONE -i NONE -l ~/.config/nvim/scripts/install-plugins.lua
```

The installer performs network operations explicitly. Normal startup uses the
prepared packages. Development checkouts take priority when present; see
[installation and deployment](docs/installation.md) for paths, transport, restoring
locked versions and Nix integration.

Start Neovim and run `:ConfigToolsInstall` to install selected language tools and
parsers through toolchain-tools. System/Nix executables can satisfy requirements.

## Usage

- `:ConfigInfo` shows the active project, languages, tools and plugin sources.
- `:checkhealth config` validates the selected configuration.
- `:PluginTools` inspects packages; `:PluginTools explain {id}` explains activation.
- `Ctrl+/` opens the searchable keymap picker; `Space t` starts grouped toggles.

Choose workflows and languages in [the configuration guide](docs/configuration.md).
Trusted project `.nvim-plugins.lua` files can select optional workflows and supply
project settings. Restart Neovim when switching project selection.

## Documentation

- [Installation, dependencies and deployment](docs/installation.md).
- [Profiles, languages and platform settings](docs/configuration.md).
- [Editing, language and project workflows](docs/workflows.md).
- [Keymaps, toggles and command ownership](docs/keymaps.md).
- [Architecture and lifecycle](docs/architecture.md).
- [Local validation and performance measurements](docs/testing.md).

Each plugin owns its complete `:help` reference. Configuration owns personal keys,
feature selection and integration policy. See [the documentation style](docs/documentation-style.md)
for this repository and the plugin collection.

## Development

```sh
python3 scripts/check-docs.py
sh tests/smoke.sh native
sh tests/smoke.sh integration
```

Tests run locally; this configuration repository has no CI workflow. Optional
compatibility, real-server acceptance and isolated GitHub installation checks are
documented in [the validation guide](docs/testing.md#health-and-testing).
