return {
  {
    -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    -- NOTE: This plugin cannot be lay loaded. Doing that will loose the ability of inlay hint <2026.04.28, lzx>
    -- lazy = false,
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      -- Show lsp status on the bottom-left
      "j-hui/fidget.nvim",
    },
    opts = {
      servers = require("config.languages").enabled_lsp_servers(),
    },
    config = function(_, opts)
      vim.lsp.enable(opts.servers)
    end,
  },
}
