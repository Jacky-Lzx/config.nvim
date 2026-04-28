return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = { "gdscript", "godot_resource" },
    },
  },

  {
    "mason-org/mason.nvim",
    optional = true,
    opts_extend = { "ensure_installed" },
    opts = { ensure_installed = { "gdscript-formatter", "gdtoolkit" } },
  },

  -- linter
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        gdscript = { "gdlint" },
      },
    },
  },

  -- formatter
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        gdscript = { "gdscript-formatter" },
      },
    },
  },
}
