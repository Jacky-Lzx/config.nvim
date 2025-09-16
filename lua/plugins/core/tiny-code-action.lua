return {
  {
    "rachartier/tiny-code-action.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      {
        "folke/snacks.nvim",
        opts = {
          -- terminal = {},
        },
      },
    },
    event = "LspAttach",
    -- stylua: ignore
    keys = {
      { "<leader>a",   function() require("tiny-code-action").code_action({}) end, desc = "[LSP] Code action", noremap = true, silent = true, },
      { "<A-a>",   function() require("tiny-code-action").code_action({}) end, desc = "[LSP] Code action", mode = "i", noremap = true, silent = true, },
      -- { "<leader>gra", function() require("tiny-code-action").code_action({}) end, desc = "[LSP] Code action", noremap = true, silent = true, },
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
      picker = {
        "snacks",
        opts = {
          layout = {
            reverse = false,
            layout = {
              backdrop = false,
              width = 0.8,
              min_width = 100,
              height = 0.8,
              min_height = 3,
              box = "vertical",
              border = "rounded",
              title = "{title}",
              title_pos = "center",
              { win = "input", height = 1, border = "bottom" },
              { win = "list", height = 5, border = "none" },
              -- { win = "preview", title = "{preview}", height = 0.4, border = "top" },
              { win = "preview", title = "{preview}", border = "top" },
            },
          },
        },
      },
    },
  },
}
