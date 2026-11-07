return {
  servers = { "vtsls", "vue_ls" },
  tools = {
    {
      package = "vue-language-server",
      executable = "vue-language-server",
    },
    { package = "vtsls", executable = "vtsls" },
    { executable = "npm" },
    { package = "prettierd", executable = "prettierd" },
    { executable = "prettier" },
  },
  parsers = { "vue", "javascript", "typescript", "html", "css" },
  formatters = {
    vue = { "prettierd" },
    javascript = { "prettierd", "prettier", stop_after_first = true },
    typescript = { "prettierd" },
  },
}
