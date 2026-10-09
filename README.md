# Neovim configuration

A modular configuration for Neovim 0.12 or newer, with a small native core and optional features for editing, languages, navigation, and display.
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
Each plugin feature checks its own dependencies. An unavailable feature leaves the core and other installed features usable.
Health checks report what needs installation.

Use `NVIM_CONFIG_PROFILE=core nvim` to start with native editing only.
Personal overrides can be placed in the ignored `lua/config/local.lua`:

```lua
return {
  features = { theme = true, input = false, lsp = true, picker = true, treesitter = true, textobjects = true, git = true, statusline = true, buffers = true, comments = true },
  languages = { lua = true },
}
```

Settings are resolved once at startup; restart after changing them.
Theme, input, LSP, Picker, managed Tree-sitter, textobjects, Git, statusline, buffer tabs, and comments can be disabled independently; `languages.lua = false` disables the Lua server.
The core profile disables all ten features even when a personal override enables them.

## Theme

Catppuccin Mocha loads before the input and Picker plugins, with transparent editor and floating-window backgrounds.
The theme owns colors for completion, native LSP diagnostics, Picker, and Git differences.
Selection, search matches, line numbers, matching parentheses, signature parameters, and Picker cursor lines use custom highlights.
Catppuccin applies these highlights when the colorscheme loads, including after switching away and back.
The theme uses its cache under Neovim's standard cache directory.

Disable it with `features.theme = false` for the native Habamax theme.
A missing theme checkout also leaves Habamax available and does not block other installed features.
Install selected dependencies with `:ConfigPluginsInstall` and restart Neovim.

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

## Comments

mini.comment toggles line comments using the buffer's `commentstring` or the language at the cursor in an active Tree-sitter parser.
It respects indentation and counts, pads comment delimiters with spaces, and comments blank lines without trailing whitespace.

| Key | Behavior |
| --- | -------- |
| `Space /` in Normal mode | Toggle the current line; a count selects consecutive lines |
| `Space /` in Visual mode | Toggle all lines in the selection |
| `gc` followed by a motion or textobject | Toggle the operated lines, for example `gcj`, `gcap`, or `gcaf` |
| `gc` in Visual or Operator-pending mode | Select the contiguous comment block, for example `ygc` or `dgc` |

Normal-mode toggles support dot-repeat, and edits can be undone with `u`.
`gci` and `gco` retain the Picker mappings for LSP incoming and outgoing calls; use `gcaf` or a Visual selection when commenting a function.
The existing native `gcc` mapping remains available.
Files without a comment format receive a notice and remain unchanged.
The feature works without completion, a language server, managed Tree-sitter, or a theme.
Disable it with `features.comments = false`.
When disabled or unavailable, Neovim's native commenting remains available; `Space /` is installed only when this feature is active.

## Textobjects

mini.ai extends `a`/`i` selection in Visual and Operator-pending modes, with a search neighborhood of 500 lines.
Native objects such as `iw` remain available.
Objects work with operators such as `y`, `d`, and `c`, counts, undo, and dot-repeat.

| Object | Behavior |
| ------ | -------- |
| `af` / `if` | Function definition / body |
| `ao` / `io` | Code block, conditional, or loop / body |
| `ac` / `ic` | Class / body, when supplied by a language query |
| `aa` / `ia` | Argument |
| `au` / `iu` | Function call including its dotted name / arguments |
| `aU` / `iU` | Function call excluding a dotted prefix / arguments |
| `at` / `it` | Tag / contents |
| `ad` / `id` | Digits |
| `ae` / `ie` | CamelCase or snake_case component |

Brackets and quotes retain mini.ai's builtin objects.
Use `an`/`in` for the next object, `al`/`il` for the previous object, and `g[`/`g]` followed by an object identifier to move to its outer edges.
For example, `vaf` selects a function, `dif` deletes its body, and `yinf` yanks the next function's body.

Syntax-based objects use Neovim's parser and native query API.
The configuration supplies `queries/lua/textobjects.scm` for Lua functions and code blocks; Lua has no class query.
These objects also work with Neovim's bundled Lua parser when managed Tree-sitter is disabled.
Missing parsers or queries leave the buffer unchanged and provide no-match feedback; pattern-based objects remain usable.
`:checkhealth config` reports query availability for selected languages.
Disable the feature with `features.textobjects = false`; the core profile uses native textobjects.

## Syntax highlighting

Neovim 0.12 already provides a Lua parser and native Lua highlighting.
The Tree-sitter feature manages parser and query versions for selected languages and enables highlighting through Neovim's native highlighting API.
Lua declares its parser and filetypes in `lua/languages/lua.lua`, independently of its language server.
Catppuccin supplies Tree-sitter capture colors through its standard highlights.

Run `:ConfigPluginsInstall` and restart to install the selected plugin repositories.
Then run `:TSInstallConfigured` to compile missing or outdated parsers for selected languages, and restart to use those versions.
The command runs asynchronously; `:TSLog` shows installation progress and failures.
Installation requires `curl`, `tar`, `tree-sitter-cli` 0.26.1 or newer, and a C compiler (`CC`, or `cc` by default).
A repeated command leaves already-current parsers intact.
Normal startup does not download or update parsers.

Parser libraries, queries, and revision records live under `stdpath("data")/site`; downloads and builds use the standard cache directory.
The locked nvim-treesitter revision supplies grammar revisions and queries.
`:ConfigInfo` shows selected parsers and their revisions; `:checkhealth config` reports missing/outdated managed parsers and installation-tool availability.
Missing installation tools do not prevent existing parsers from highlighting files.
Without the plugin or a managed Lua parser, Neovim's bundled Lua highlighting remains available.
When a declared parser cannot start, the feature falls back to Vim syntax highlighting.

`features.treesitter = false` disables managed Tree-sitter support; `languages.lua = false` excludes Lua from parser installation.
Neovim's built-in filetype behavior remains available in the core profile.

## Picker

Snacks Picker provides file, content, buffer, diagnostic, and LSP selection, and loads on its first mapped action.
Only the Picker module is enabled.
It also supplies native `vim.ui.select` dialogs after loading.
The following Normal-mode mappings are available when Picker is installed and enabled:

| Key        | Behavior                          |
| ---------- | --------------------------------- |
| `Space sf` | Find files                        |
| `Space sg` | Search file contents              |
| `Space sb` / `Space ,` | Switch buffers          |
| `Space sR` | Recent files                      |
| `Space sr` | Resume the last picker            |
| `Space sd` | Diagnostics under the current directory |
| `Space sD` | Current-buffer diagnostics         |
| `gd`       | Definitions                       |
| `gD`       | Declarations                      |
| `gi`       | References                        |
| `gI`       | Implementations                   |
| `gy`       | Type definitions                  |
| `gci`      | Incoming calls                    |
| `gco`      | Outgoing calls                    |
| `Space ss` | Symbols in the current document   |
| `Space sS` | Workspace symbols                 |

Results use a vertical layout with preview above the list and input at the bottom.
Typing filters results; Enter confirms, and a single jump target is confirmed automatically.
Requests use the active language server, so availability depends on its supported methods.

File and content search use the current working directory, including changes made with `:cd` or `:lcd`.
File search prefers `fd`/`fdfind`, then `rg --files`, then `find` on Unix.
Content search requires `rg` (ripgrep).
The `fd` and `rg` backends respect Git ignore rules; the basic `find` fallback does not.
Missing search tools produce a notice while buffer, recent-file, diagnostic, and LSP pickers remain available.
`:checkhealth config` reports the active file finder and content-search executable.

Inside Picker, `Alt j/k` moves down/up, `Alt u/d` scrolls the list, and `Ctrl u/d` scrolls the preview.
`Tab` selects an item and moves to the previous item; `Shift Tab` selects and moves to the next.
`Alt Up/Down` navigates input history.
`Ctrl y` copies selected paths or text to the clipboard; `Ctrl o` opens selected items with the system app.
These mappings apply in both Insert and Normal modes.
Input completion keeps its own Enter and Tab behavior outside Picker.

## Git

Gitsigns loads when opening or creating a file and attaches to tracked and untracked files in Git repositories.
Changes color line numbers by default; Git signs and current-line blame start disabled.
The theme supplies Git difference colors.
Mappings are buffer-local and available after Gitsigns attaches; the three display toggles affect all attached buffers.

| Key | Behavior |
| --- | -------- |
| `]h` / `[h` | Next / previous hunk |
| `]H` / `[H` | Last / first hunk |
| `Space ggs` / `Space ggr` | Stage / reset hunk; Visual mode operates on selected lines |
| `Space ggS` / `Space ggR` | Stage / reset all buffer changes |
| `Space ggp` / `Space ggP` | Floating / inline hunk preview |
| `Space ggd` / `Space ggD` | Diff against the index / previous commit |
| `Space ggq` / `Space ggQ` | Current-buffer / repository hunks in quickfix |
| `ih` in Visual or Operator-pending mode | Select the current hunk |
| `Space tgb` | Toggle current-line blame |
| `Space tgw` | Toggle word differences |
| `Space tgs` | Toggle Git signs |

Staging a staged hunk unstages it. Reset edits the buffer and can be undone with `u`; save with `:w` to update the working file.
Use `qq` in the comparison window to close the diff view.
In diff windows, hunk navigation passes through to the native keys.
Staging and reset run only on explicit actions.
Install Git separately on PATH. Missing Git or Gitsigns leaves other features usable and is reported by `:checkhealth config`.
Disable this feature with `features.git = false`; the core profile disables it.

## Statusline and buffer tabs

Lualine displays the mode, Git branch and changes, native diagnostics, filename and modified state, encoding, format, filetype, progress, and cursor location.
Git information comes from the attached Gitsigns buffer without starting another Git process while drawing the statusline.
The window bar shows the filename and attached language-server names and progress.
A recording indicator shows the active macro register.
Catppuccin supplies the statusline colors; with the theme disabled or unavailable, Lualine uses the active colorscheme.

Barbar displays open buffers, hides the bar when only one buffer and one tab page remain, and disables animations.
Closing a buffer preserves the window layout. Unsaved changes remain protected; save or explicitly discard them before closing.
Catppuccin supplies buffer-tab colors.

| Key | Behavior |
| --- | -------- |
| `Alt h/l`, `[b` / `]b` | Previous / next buffer |
| `Alt 1` through `Alt 9` | Select a buffer by its tab position |
| `Alt Shift ,/.` | Move the current buffer left / right |
| `Alt </>` | Move left / right with legacy terminal encoding |
| `Alt w` | Close the buffer |
| `Alt u` | Restore the last closed file |

These mappings apply in Normal mode; completion and snippets retain their Insert-mode mappings.
Buffer positions follow the displayed order, including manual moves.
The tabs represent buffers; Neovim tab pages remain available with native commands.

Disable these features independently with `features.statusline = false` or `features.buffers = false`.
Missing Lualine leaves Barbar usable, and missing Barbar leaves Lualine usable.
Both use optional nvim-web-devicons; missing icons leaves text labels and navigation available.
Run `:ConfigPluginsInstall` and restart Neovim to install the selected UI plugins and file icons.
The core profile retains Neovim's native statusline and tabline.

## Structure

- `init.lua` delegates startup to `config`.
- `lua/config/` owns startup, selection, plugin-manager bootstrap, configuration information, and health checks.
- `lua/core/` owns native options, keymaps, autocommands, and commands.
- `lua/features/comments/` owns line-comment mappings and plugin setup.
- `lua/features/statusline/` owns statusline sections, window bars, and readonly display components.
- `lua/features/buffers/` owns buffer tabs and their Normal-mode mappings.
- `lua/features/ui/` owns shared optional file-icon availability.
- `lua/features/git/` owns buffer Git differences, actions, mappings, and dependency health checks.
- `lua/features/textobjects/` owns mini.ai specifications and query health checks.
- `queries/` supplies native language queries for syntax-based textobjects.
- `lua/features/treesitter/` owns native highlighting, explicit parser installation, dependency checks, and health reporting.
- `lua/features/theme/` owns theme options, plugin integrations, and custom highlights.
- `lua/features/input/` owns completion, snippets, pairing, and their key interactions.
- `lua/features/lsp/` owns native client setup, buffer mappings, and diagnostics.
- `lua/features/picker/` owns result selection, its mappings, and window layout.
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
Tree-sitter checks also copy the installed Lua parser, queries, and revision record from the adjacent `site` directory; `NVIM_TEST_PARSER_ROOT` can select a different parser source.
The input and Picker checks send real keys to embedded Neovim processes and observe menus, snippet fields, selections, jumps, and saved files.
Core, missing-dependency, personal-override, and missing-pairing cases are checked independently.
`--live` additionally requires `lua-language-server` on PATH and verifies actual diagnostics, hover, definition, rename, formatting, completion confirmation, client reuse, and LSP with input disabled.
It also verifies Picker definitions, references, document/workspace symbols, and no-result feedback for call hierarchy methods unavailable in Lua Language Server.
Missing input and Picker dependencies are checked independently.
Search checks exercise actual file enumeration and ripgrep results, previews, resume, buffer/recent-file selection, and diagnostic jumps.
They also exercise the ripgrep file-finder fallback and missing-tool behavior.

Theme checks cover Mocha colors, transparent windows, highlight restoration, completion/Picker integration, and disabled, missing, core, and theme-only configurations.

Tree-sitter checks verify real Lua parsing and capture colors, editing, native/Vim-syntax fallback, dependency notices, idempotent installation, and disabled, core, language-disabled, and standalone configurations.

Textobject checks send real Visual and operator keys, verify selected text and edits, counts, next/previous selection, boundary motions, undo and dot-repeat, and exercise missing plugins/queries, unsupported parsers, disabled, core, and standalone cases.

Git checks use temporary repositories and real keys to verify signs, hunk navigation and selection, partial/full staging and reset, previews, diff views, quickfix lists, display toggles, and disabled, core, missing-dependency, and standalone configurations.

UI checks render the statusline, window bar, and buffer tabs through Neovim and send real keys for mode changes, macro recording, switching, reordering, closing, and restoration. They cover Git changes, diagnostics, theme restoration, missing plugins/icons, standalone features, disabled features, and the core profile; `--live` also checks the window bar with an actual Lua language server.

Comment checks send real Normal, Visual, and Operator-pending keys to verify toggling, counts, reverse selections, indentation, blank lines, dot-repeat, undo, comment-block selection/deletion, filetype and buffer comment formats, code textobjects, and missing/disabled/core/standalone behavior.
