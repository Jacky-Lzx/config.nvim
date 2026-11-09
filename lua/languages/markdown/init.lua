return {
  servers = { "marksman", "typos_lsp" },
  tools = {
    { package = "marksman", executable = "marksman" },
    { package = "prettierd", executable = "prettierd" },
    { package = "prettier", executable = "prettier" },
    { package = "mmdc", executable = "mmdc" },
    { package = "typos-lsp", executable = "typos-lsp" },
    { executable = "deno" },
    { executable = "gh" },
  },
  parsers = { "markdown", "markdown_inline" },
  formatters = {
    -- Run the first available formatter
    markdown = { "prettierd", "prettier", stop_after_first = true },
  },
  plugins = { "languages.markdown.plugins" },
}
