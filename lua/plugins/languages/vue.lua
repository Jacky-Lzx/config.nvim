return {
  -- 安装 Volar (vue-language-server)
  {
    "williamboman/mason.nvim",
    optional = true,
    opts = {
      ensure_installed = { "vue-language-server", "typescript-language-server", "vtsls" },
    },
    opts_extend = { "ensure_installed" },
  },

  -- 可选：语法高亮
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = {
      ensure_installed = { "vue", "javascript", "typescript", "html", "css" },
    },
    opts_extend = { "ensure_installed" },
  },

  -- 可选：格式化（使用 prettierd）
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        vue = { "prettierd" },
        javascript = { "prettierd" },
        typescript = { "prettierd" },
      },
    },
  },
}
