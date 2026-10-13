return {
  {
    "Jacky-Lzx/code-actions.nvim",
    dev = true,
    dependencies = { "folke/snacks.nvim" },
    event = "LspAttach",
    keys = {
      {
        "<leader>a",
        function()
          require("code_actions").code_action()
        end,
        desc = "[LSP] Code action",
        mode = { "n", "x" },
      },
      {
        "<A-a>",
        function()
          require("code_actions").code_action()
        end,
        desc = "[LSP] Code action",
        mode = "i",
      },
    },
    opts = {
      backend = "delta", -- Set "vim" to use the native diff preview.
      delta = {
        args = {
          "--file-style=omit",
          "--hunk-header-style=file line-number syntax",
        },
      },
    },
    config = function(_, opts)
      require("code_actions").setup(opts)
    end,
  },
}
