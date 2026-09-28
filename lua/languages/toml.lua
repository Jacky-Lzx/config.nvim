return {
  servers = { "taplo" },
  tools = {
    { mason = "taplo", executable = "taplo" },
  },
  parsers = { "toml" },
  formatters = {
    toml = { "taplo" },
  },
}
