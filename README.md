# Neovim configuration

A small native configuration for Neovim 0.12 or newer.
It starts without external plugins, tools, or network access.

## Usage

Place the configuration in Neovim's standard configuration directory and run `nvim`.
An alternative configuration directory can be selected with `NVIM_APPNAME`.
All configuration and storage paths follow Neovim's `stdpath()` values.

- `:ConfigInfo` shows the Neovim version and active paths.
- `:checkhealth config` checks the runtime and configuration entry.
- `:Explore` opens the native file browser.

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
Insert-mode Enter and Tab use native behavior.

## Structure

- `init.lua` delegates startup to `config`.
- `lua/config/` owns startup, configuration information, and health checks.
- `lua/core/` owns native options, keymaps, autocommands, and commands.
- `tests/` checks actual startup and editing behavior in temporary XDG directories.

Modules do not configure the editor merely by being required.
Startup invokes their `setup()` functions explicitly.
Core code depends only on Neovim's APIs.
Shared plugin setup and language workflows belong in their own modules when introduced.

## Validation

```sh
./tests/run.sh
stylua --check init.lua lua tests
```

The tests isolate config, data, state, cache, logs, and fixtures, and run from an unrelated working directory.
They do not install dependencies or use personal project files.
