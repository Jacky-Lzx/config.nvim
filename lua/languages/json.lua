return {
  servers = { "jsonls" },
  tools = {
    { mason = "json-lsp", executable = "vscode-json-language-server" },
    { mason = "jq", executable = "jq" },
  },
  parsers = { "json", "json5" },
  formatters = {
    json = { "jq" },
  },
}
