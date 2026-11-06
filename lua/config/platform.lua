-- Platform entries override defaults by field; command lists are replaced as a whole.
-- User paths may start with ~; managed tool paths are resolved through toolchain.
return {
  defaults = {
    shell = { "fish" },
    shell_fallback = "sh",
    python_host = "~/.uv/neovim/bin/python3",
    python = { "python3", "python" },
    virtualenv_python = "bin/python",
    dev_plugin_root = "~/Documents/Github/nvim_plugins",
  },
  macos = {
    sysname = "Darwin",
    opener = { "open" },
    jdtls_java_home = {
      "/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home",
      "/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home",
    },
  },
  linux = {
    sysname = "Linux",
    opener = { "xdg-open" },
  },
  other = {},
}
