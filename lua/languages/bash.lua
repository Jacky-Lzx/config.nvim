return {
  servers = { "bashls" },
  tools = {
    { mason = "shfmt", executable = "shfmt" },
    { mason = "bash-language-server", executable = "bash-language-server" },
    { executable = "fish" },
  },
  parsers = { "bash" },
  formatters = {
    sh = { "shfmt" },
    fish = { "fish_indent" },
  },
  linters = {
    fish = { "fish" },
    bash = { "bash" },
  },
  requires = { formatters = { fish = "fish" }, linters = { fish = "fish" } },
}
