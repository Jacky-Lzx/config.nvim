local html_beautify = require("config.platform").executable("html_beautify")

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = { "html" },
    },
  },

  {
    "mason-org/mason.nvim",
    optional = true,
    opts_extend = { "ensure_installed" },
    opts = { ensure_installed = { "superhtml" } },
  },

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        -- Should install js-beautify first `https://github.com/beautifier/js-beautify`
        html = html_beautify and { "html_beautify" } or nil,
      },
    },
    optional = true,
  },
}
