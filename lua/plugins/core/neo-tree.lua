return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    lazy = false, -- neo-tree will lazily load itself
    enabled = false,
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons", -- optional, but recommended
      {
        "romgrk/barbar.nvim",
        optional = true,
        opts = {
          -- Set the filetypes which barbar will offset itself for
          sidebar_filetypes = {
            ["neo-tree"] = { text = "Neo-Tree", event = "BufWipeout", align = "center" },
          },
        },
      },
    },
    keys = {
      { "<leader>e", "<CMD>Neotree toggle<CR>", mode = { "n" }, desc = "[Neotree] Toggle Neotree" },
    },
    opts = {
      filesystem = {
        window = {
          mappings = {
            ["s"] = "system_open",
          },
        },
      },
      commands = {
        system_open = function(state)
          local node = state.tree:get_node()
          local path = node:get_id()
          -- macOs: open file in default application in the background.
          vim.fn.jobstart({ "open", path }, { detach = true })
        end,
      },
    },
  },
}
