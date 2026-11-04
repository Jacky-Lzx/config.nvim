return {
  {
    -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      -- Completion and file-operation capabilities must be installed before enabling servers.
      "completion-tools.nvim",
      "file-tools.nvim",
      "toolchain-tools.nvim",
    },
    opts = {
      servers = require("languages").current().servers,
    },
    config = function(_, opts)
      vim.lsp.config("*", {
        capabilities = vim.tbl_deep_extend(
          "force",
          {},
          require("completion-tools").get_lsp_capabilities(),
          require("file_tools").capabilities()
        ),
      })
      vim.lsp.enable(opts.servers)
    end,
  },
}
