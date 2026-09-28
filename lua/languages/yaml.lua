return {
  servers = { "yamlls" },
  tools = {
    { mason = "yaml-language-server", executable = "yaml-language-server" },
    { mason = "prettierd", executable = "prettierd" },
  },
  parsers = { "yaml" },
  formatters = {
    yaml = { "prettierd" },
  },
}
