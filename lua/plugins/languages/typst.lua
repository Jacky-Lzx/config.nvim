local M = {
  {
    "nvim-treesitter/nvim-treesitter",
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = { "typst" },
    },
  },

  {
    "mason-org/mason.nvim",
    optional = true,
    opts_extend = { "ensure_installed" },
    opts = { ensure_installed = { "typstyle", "tinymist" } },
  },

  -- formatter
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        typst = { "typstyle" },
      },
      formatters = {
        typstyle = {
          prepend_args = { "-l", "120", "--wrap-text" },
        },
      },
    },
  },

  {
    "chomosuke/typst-preview.nvim",
    ft = "typst",
    version = "1.*",
    opts = {
      -- Use tinymist installed from Mason
      dependencies_bin = {
        ["tinymist"] = "tinymist",
      },
    },
  },
}

return M
