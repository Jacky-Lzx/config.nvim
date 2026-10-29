return {
  {
    "Jacky-Lzx/lsp-tools.nvim",
    url = "git@github.com:Jacky-Lzx/lsp-tools.nvim.git",
    dev = true,
    dependencies = { "folke/snacks.nvim" },
    event = "LspAttach",
    keys = {
      {
        "]r",
        function()
          require("lsp-tools").jump_reference(vim.v.count1)
        end,
        desc = "[LSP] Next reference",
        mode = "n",
      },
      {
        "[r",
        function()
          require("lsp-tools").jump_reference(-vim.v.count1)
        end,
        desc = "[LSP] Previous reference",
        mode = "n",
      },
      {
        "<leader>a",
        function()
          require("lsp-tools").code_action()
        end,
        desc = "[LSP] Code action",
        mode = { "n", "x" },
      },
      {
        "<A-a>",
        function()
          require("lsp-tools").code_action()
        end,
        desc = "[LSP] Code action",
        mode = "i",
      },
    },
    opts = {
      code_actions = {
        backend = "delta", -- Set "vim" to use the native diff preview.
        delta = {
          args = {
            "--file-style=omit",
            "--hunk-header-style=file line-number syntax",
          },
        },
      },
    },
    config = function(_, opts)
      require("lsp-tools").setup(opts)
    end,
  },
}
