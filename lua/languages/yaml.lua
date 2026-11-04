return {
  servers = { "yamlls" },
  tools = {
    { package = "yaml-language-server", executable = "yaml-language-server" },
    { package = "prettierd", executable = "prettierd" },
  },
  parsers = { "yaml" },
  formatters = {
    yaml = { "prettierd" },
  },
}
