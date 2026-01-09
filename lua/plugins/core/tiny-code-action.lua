return {
  {
    "rachartier/tiny-code-action.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim",
    },
    event = "LspAttach",
    -- stylua: ignore
    keys = {
      { "<leader>a", function() require("tiny-code-action").code_action({}) end, desc = "[LSP] Code action",             noremap = true, silent = true, },
      { "<A-a>",     function() require("tiny-code-action").code_action({}) end, desc = "[LSP] Code action", mode = "i", noremap = true, silent = true, },
    },
    opts = {
      backend = "delta",
      backend_opts = {
        delta = {
          -- The arguments to pass to delta
          -- If you have a custom configuration file, you can set the path to it like so:
          args = {
            -- "--config " .. os.getenv("HOME") .. "/.config/nvim/configs/.gitconfig",
          },
        },
      },
      picker = { "snacks", opts = {} },
    },
  },
}
