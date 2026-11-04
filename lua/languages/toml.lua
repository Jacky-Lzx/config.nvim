return {
  servers = { "taplo" },
  tools = {
    { package = "taplo", executable = "taplo" },
  },
  parsers = { "toml" },
  formatters = {
    toml = { "taplo" },
  },
}
