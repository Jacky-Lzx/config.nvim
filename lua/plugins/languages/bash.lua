local has_fish = require("config.platform").executable("fish") ~= nil

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = { "bash" },
    },
  },

  {
    "mason-org/mason.nvim",
    optional = true,
    opts_extend = { "ensure_installed" },
    opts = { ensure_installed = { "shfmt", "bash-language-server" } },
  },

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        sh = { "shfmt" },
        fish = has_fish and { "fish_indent" } or nil,
      },
    },
    optional = true,
  },

  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        fish = has_fish and { "fish" } or nil,
        bash = { "bash" },
      },
    },
  },
}
