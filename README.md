# Neovim configuration

A modular configuration for Neovim 0.12 or newer, with a small native core and optional input and language features.
Normal startup does not install or update plugin repositories.

## Usage

Place the configuration in Neovim's standard configuration directory and run `nvim`.
An alternative configuration directory can be selected with `NVIM_APPNAME`.
All configuration and storage paths follow Neovim's `stdpath()` values.

- `:ConfigInfo` shows the Neovim version and active paths.
- `:checkhealth config` checks the runtime and configuration entry.
- `:Explore` opens the native file browser.

Run `:ConfigPluginsInstall` to install the selected plugins, then restart Neovim.
Remote plugin revisions are recorded in `lazy-lock.json`.
If a required plugin is absent, the native core remains usable and health checks report what needs installation.

Use `NVIM_CONFIG_PROFILE=core nvim` to start with native editing only.
Personal overrides can be placed in the ignored `lua/config/local.lua`:

```lua
return {
  features = { input = false, lsp = true },
  languages = { lua = true },
}
```

Settings are resolved once at startup; restart after changing them.
Input and LSP can be disabled independently; `languages.lua = false` disables the Lua server.
The core profile disables input and LSP even when a personal override enables them.

## Editing

The leader and local leader are Space.
Indentation defaults to two spaces; native filetype scripts and project EditorConfig files can specialize it.
Typed text does not automatically wrap or continue comment prefixes.
Undo history persists in Neovim's standard state directory.

| Key                           | Behavior                                                            |
| ----------------------------- | ------------------------------------------------------------------- |
| `Q` in Normal or Visual mode  | Quit Neovim                                                         |
| `qq` in Normal or Visual mode | Close the current window                                            |
| `Ctrl h/j/k/l`                | Move between windows in Normal mode; move the cursor in Insert mode |
| `jk`                          | Leave Insert mode                                                   |
| `H` / `L`                     | Move to the first nonblank character / end of line                  |
| `<` / `>` in Visual mode      | Adjust indentation and retain the selection                         |
| `Space J` / `Space K`         | Move to the next / previous quickfix entry                          |
| `Alt z`                       | Toggle wrapping in the current window                               |

Use `:w` to save; `:W`, `:Wq`, and `:Q` are aliases for `:w`, `:wq`, and `:q`.

A bare Visual `:w`, `:w!`, `:write`, or `:write!` saves the entire buffer.
Commands with arguments, such as `:w filename`, preserve the selection range.
Substitutions and other ranged commands also retain their range.

## Input

The input module configures blink.cmp and LuaSnip together, with optional local pairing.
Completion offers LSP, path, snippet, and buffer sources; language servers are configured separately.
Completion preselects the first item without inserting it while browsing.
Enter and Tab confirm that selection; Shift-Enter inserts a newline without accepting it.
Ghost text previews the selected item, and documentation opens after 200 ms.

| Key                            | Behavior                                                              |
| ------------------------------ | --------------------------------------------------------------------- |
| `Ctrl Space`                   | Show completion or its documentation                                  |
| `Ctrl n/p`, `Alt j/k`, Up/Down | Select the next / previous completion item                            |
| `Alt d/u`                      | Move forward / backward by five completion items                      |
| `Alt /`                        | Toggle the completion menu                                            |
| `Alt n/p`                      | Cycle completion sources forward / backward                           |
| `Ctrl e`                       | Cancel completion                                                     |
| `Ctrl y`                       | Confirm the selected or first completion item                         |
| `Ctrl u/d`, `Ctrl b/f`         | Scroll completion documentation                                       |
| `Enter`                        | Confirm a selected item; otherwise expand a pair newline or use Enter |
| `Shift Enter`                  | Close completion and insert a native newline                          |
| `Tab`                          | Confirm a selected item; otherwise use native Tab                     |
| `Shift Tab`                    | Move to the previous snippet field                                    |
| `Alt j/k` with the menu closed | Move to the next / previous active snippet choice                     |
| `Alt c`                        | Select an active snippet choice from a list                           |
| Backtick in Visual mode        | Cut and store the selection for snippet selected-text variables       |
| `Space tp`                     | Toggle local pairing                                                  |

Path, LSP, buffer, and snippet sources have score offsets of 95, 60, 20, and 100.
Buffer completion reads all normal buffers; LSP Text and Snippet items are excluded.
Snippet completion is suppressed immediately after a source trigger character.

Source cycling is buffer-local: all configured sources, buffer words, snippets, then LSP/path.
Tab does not jump or expand a typed snippet trigger; accepting a snippet completion expands it.

Command-line completion uses the same navigation, five-item jumps, menu toggle, and Tab confirmation.
Enter executes the command as typed, including the whole-buffer behavior of a bare Visual `:w`.
Terminal completion remains disabled.
The fuzzy matcher prefers Rust, downloading its prebuilt library when needed and warning before a Lua fallback.
Plugin installation builds LuaSnip's jsregexp component with `make install_jsregexp`.
LuaSnip loads custom definitions from `lua/snippets/<filetype>.lua` when that directory exists.
Automatic snippets and root/child snippet linking are enabled; Markdown also inherits TeX definitions.
Manual expansion starts a separate undo step.
`:LuaSnipList` lists snippets, and `:LuaSnipEdit` opens their definitions.

Pairing uses the external `pairs.nvim` checkout under `NVIM_DEV_PLUGIN_ROOT`, defaulting to `~/Documents/Github/nvim_plugins`.
Its source is maintained separately and is not included in the plugin lockfile.
An unavailable checkout disables pairing while completion, snippets, and ordinary Enter remain available.
`:checkhealth config` reports the local path and Git revision.

Enter and Tab ownership stays with the input module; pairing contributes its newline action without overriding completion confirmation.
The deferred pair newline mapping applies preceding typed text before inspecting the buffer.

## Languages

Language selection lives in `lua/languages/`; the first supported language is Lua.
Native server configurations live in `lsp/<server>.lua`, with Lua configured in `lsp/lua_ls.lua`.
Neovim discovers these files through its runtime path; the LSP feature enables selected servers and adds completion capabilities while preserving server initialization hooks.
Neovim's native LSP client starts `lua-language-server` when an existing or newly named Lua buffer is opened.
Install that executable separately and make it available on PATH; startup does not download language tools.
A missing executable leaves editing available and is reported by `:checkhealth config`.
`:ConfigLspInfo` shows selected servers and clients attached to the current buffer.

Lua projects use the nearest `.luarc.json` or `.luarc.jsonc` as their root, followed by a Git root, then the file's directory.
Unnamed and special buffers do not start a server.
Files in the same root share a client.
The configuration's own Lua files receive LuaJIT, the `vim` global, and Neovim's runtime library unless a project `.luarc` file is present.
Other Lua projects retain their own runtime and library settings.
Lua server logs and generated metadata use Neovim's standard state and cache directories.

When input features are enabled, Blink supplies completion capabilities to the server.
Native LSP also works with input plugins disabled or unavailable.
The following mappings are installed only in buffers with an attached client:

| Key        | Behavior                         |
| ---------- | -------------------------------- |
| `Space d`  | Show diagnostics in a float      |
| `Space gk` | Show signature help              |
| `Space gf` | Format the buffer                |
| `Space rn` | Rename the symbol                |
| `Space gr` | List references                  |
| `Space gt` | Go to the type definition        |
| `Space wa` | Add a workspace folder           |
| `Space wr` | Remove a workspace folder        |
| `Space wl` | List workspace folders           |

Diagnostics show severity icons and virtual text, with severity sorting and rounded floats.
They update after leaving Insert mode and do not underline text.
`Space td` toggles diagnostics, `Space tv` switches between messages and compact icons, and `Space tV` toggles diagnostic lines for the current line.
Formatting is manual; project formatter settings remain owned by the language server.

## Structure

- `init.lua` delegates startup to `config`.
- `lua/config/` owns startup, selection, plugin-manager bootstrap, configuration information, and health checks.
- `lua/core/` owns native options, keymaps, autocommands, and commands.
- `lua/features/input/` owns completion, snippets, pairing, and their key interactions.
- `lua/features/lsp/` owns native client setup, buffer mappings, and diagnostics.
- `lsp/` provides native server configurations, project roots, and server settings.
- `lua/languages/` declares language selection and associated server names.
- `tests/` checks actual startup and editing behavior in temporary XDG directories.

Modules do not configure the editor merely by being required.
Startup invokes their `setup()` functions explicitly.
Core code depends only on Neovim's APIs.
Language declarations do not configure the editor merely by being required.

## Validation

```sh
./tests/run.sh
./tests/run.sh --core
./tests/run.sh --live
stylua --check init.lua lua lsp tests
```

The tests isolate config, data, state, cache, logs, and fixtures, and run from an unrelated working directory.
They do not install dependencies or use personal project files.
Full checks copy the installed plugin repositories into temporary data storage and verify their revisions against the lockfile.
The default source follows the configuration directory name or `NVIM_APPNAME`; `NVIM_TEST_PLUGIN_ROOT` can select another installed `lazy` directory.
The input checks send real keys to an embedded Neovim process and observe completion menus, snippet fields, and saved files.
Core, missing-dependency, personal-override, and missing-pairing cases are checked independently.
`--live` additionally requires `lua-language-server` on PATH and verifies actual diagnostics, hover, definition, rename, formatting, completion confirmation, client reuse, and LSP with input disabled.
