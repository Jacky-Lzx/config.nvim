return {
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = {
      ensure_installed = { "lua" },
    },
    opts_extend = { "ensure_installed" },
  },

  {
    "mason-org/mason.nvim",
    optional = true,
    opts = {
      ensure_installed = { "lua-language-server", "stylua" },
    },
    opts_extend = { "ensure_installed" },
  },

  -- formatter
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
      },
    },
  },

  -- Provide neovim config completion
  -- Have its settings in blink.cmp
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
      },
    },
  },
}
