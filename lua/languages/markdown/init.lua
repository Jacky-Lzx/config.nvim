return {
  servers = { "marksman", "harper_ls", "typos_lsp" },
  tools = {
    { package = "marksman", executable = "marksman" },
    { package = "harper-ls", executable = "harper-ls" },
    { package = "prettierd", executable = "prettierd" },
    { package = "prettier", executable = "prettier" },
    { package = "mmdc", executable = "mmdc" },
    { package = "typos-lsp", executable = "typos-lsp" },
    { executable = "deno" },
    { executable = "gh" },
  },
  parsers = { "markdown", "markdown_inline" },
  formatters = {
    -- Conform will run the first available formatter
    markdown = { "prettierd", "prettier", stop_after_first = true },
  },
  plugins = { "languages.markdown.plugins" },
}
