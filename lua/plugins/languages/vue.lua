return {
  -- 启动 vtsls + vue_ls（配置在 after/lsp/ 下）。
  -- lspconfig 由 core 在 BufReadPre 加载，这里覆盖其 config（core 的 config 为空），
  -- enable 后按 filetypes 自动 attach：打开 .vue/.ts/.js 等文件都会启动。
  {
    "neovim/nvim-lspconfig",
    optional = true,
    config = function()
      require("utils.vue_lsp").setup()
    end,
  },

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
