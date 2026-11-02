return {
  {
    -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      -- Completion capabilities must be installed before any server is enabled.
      "completion-tools.nvim",
      "mason-org/mason.nvim",
    },
    opts = {
      servers = require("languages").current().servers,
    },
    config = function(_, opts)
      vim.lsp.config("*", {
        capabilities = require("completion-tools").get_lsp_capabilities(),
      })
      vim.lsp.enable(opts.servers)
    end,
  },
}
