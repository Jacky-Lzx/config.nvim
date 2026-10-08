return {
  {
    -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      -- Completion capabilities must be installed before any server is enabled.
      "saghen/blink.cmp",
      "mason-org/mason.nvim",
      -- Show lsp status on the bottom-left
      "j-hui/fidget.nvim",
    },
    opts = {
      servers = require("languages").current().servers,
    },
    config = function(_, opts)
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(nil, true),
      })
      vim.lsp.enable(opts.servers)
    end,
  },
}
