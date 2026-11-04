return {
  servers = { "bashls" },
  tools = {
    { package = "shfmt", executable = "shfmt" },
    { package = "bash-language-server", executable = "bash-language-server" },
    { executable = "fish", optional = true },
  },
  parsers = { "bash", "fish" },
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
