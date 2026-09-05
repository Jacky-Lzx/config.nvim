return {
  -- 安装 Volar (vue-language-server)
  {
    "mason-org/mason.nvim",
    optional = true,
    opts = {
      ensure_installed = { "vue-language-server", "typescript-language-server", "vtsls" },
      post_install = {
        ["vue-language-server"] = function(package)
          require("utils.vue_lsp").ensure_typescript5(package:get_install_path())
        end,
      },
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
