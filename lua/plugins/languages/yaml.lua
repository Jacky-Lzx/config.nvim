local M = {
  -- formatter
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        yaml = { "prettier" },
      },
    },
  },
}

return M
