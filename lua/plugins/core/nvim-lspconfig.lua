return {
  {
    -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    -- NOTE: This plugin cannot be lay loaded. Doing that will loose the ability of inlay hint <2026.04.28, lzx>
    lazy = false,
    dependencies = {
      "mason-org/mason.nvim",
      -- { "folke/neodev.nvim", opts = { experimental = { pathStrict = true } } },
      -- "williamboman/mason-lspconfig.nvim",
      -- "hrsh7th/cmp-nvim-lsp",
      -- "SmiteshP/nvim-navic",
      -- Show lsp status on the bottom-left
      -- "j-hui/fidget.nvim",
    },
    opts = {},
    config = function(_, _)
      -- vim.lsp.config("typos_lsp", {
      --   settings = {
      --     typos_lsp = {
      --       init_options = {
      --         -- Custom config. Used together with a config file found in the workspace or its parents,
      --         -- taking precedence for settings declared in both.
      --         -- Equivalent to the typos `--config` cli argument.
      --         -- config = "~/code/typos-lsp/crates/typos-lsp/tests/typos.toml",
      --         -- How typos are rendered in the editor, can be one of an Error, Warning, Info or Hint.
      --         -- Defaults to error.
      --         diagnosticSeverity = "Hint",
      --       },
      --     },
      --   },
      -- })
      -- WARN:this lsp will cause a strange error when opening a markdown file with snacks.picker
      -- vim.lsp.enable("typos_lsp")
    end,
  },
}
