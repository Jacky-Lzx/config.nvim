return {
  servers = { "jsonls" },
  tools = {
    { package = "json-lsp", executable = "vscode-json-language-server" },
    { package = "jq", executable = "jq" },
  },
  parsers = { "json", "json5" },
  formatters = {
    json = { "jq" },
  },
}
