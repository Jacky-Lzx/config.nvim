return {
  servers = { "vtsls", "vue_ls" },
  tools = {
    {
      mason = "vue-language-server",
      executable = "vue-language-server",
      post_install = function(package)
        require("languages.vue.compatibility").ensure_typescript5(package:get_install_path())
      end,
    },
    { mason = "vtsls", executable = "vtsls" },
    { executable = "npm" },
    { mason = "prettierd", executable = "prettierd" },
    { executable = "prettier" },
  },
  parsers = { "vue", "javascript", "typescript", "html", "css" },
  formatters = {
    vue = { "prettierd" },
    javascript = { "prettierd", "prettier", stop_after_first = true },
    typescript = { "prettierd" },
  },
}
