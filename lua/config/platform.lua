-- Platform entries override defaults by field; command lists are replaced as a whole.
-- Mason paths are relative to stdpath("data"); user paths may start with ~.
return {
  defaults = {
    shell = { "fish" },
    shell_fallback = "sh",
    mason_bin = "mason/bin",
    python_host = "~/.uv/neovim/bin/python3",
    python = { "python3", "python" },
    virtualenv_python = "bin/python",
    debugpy_python = "mason/packages/debugpy/venv/bin/python",
    external_terminal = "kitty",
    dev_plugin_root = "~/Documents/Github/nvim_plugins",
  },
  macos = {
    sysname = "Darwin",
    opener = { "open" },
    skim_displayline = "/Applications/Skim.app/Contents/SharedSupport/displayline",
  },
  linux = {
    sysname = "Linux",
    opener = { "xdg-open" },
  },
  other = {},
}
