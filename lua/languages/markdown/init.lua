return {
  servers = { "marksman", "harper_ls", "typos_lsp" },
  tools = {
    { mason = "marksman", executable = "marksman" },
    { mason = "harper-ls", executable = "harper-ls" },
    { mason = "prettierd", executable = "prettierd" },
    { mason = "prettier", executable = "prettier" },
    { mason = "mmdc", executable = "mmdc" },
    { mason = "typos-lsp", executable = "typos-lsp" },
    { executable = "deno" },
    { executable = "gh" },
  },
  parsers = { "markdown", "markdown_inline" },
  formatters = {
    -- Conform will run the first available formatter
    markdown = { "prettierd", "prettier", stop_after_first = true },
  },
  plugins = { { import = "languages.markdown.plugins" } },
}
