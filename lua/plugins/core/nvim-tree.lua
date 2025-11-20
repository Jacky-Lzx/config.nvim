return {
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      {
        "romgrk/barbar.nvim",
        optional = true,
        opts = {
          -- Set the filetypes which barbar will offset itself for
          sidebar_filetypes = {
            -- Default values: {event = 'BufWinLeave', text = '', align = 'left'}
            NvimTree = { text = "NvimTree", event = "BufWinLeave", align = "center" },
          },
        },
      },
    },
    keys = {
      { "<leader>e", "<CMD>NvimTreeToggle<CR>", mode = { "n" }, desc = "[NvimTree] Toggle NvimTree" },
    },
    opts = {
      update_focused_file = {
        enable = true,
      },
    },
  },
}
