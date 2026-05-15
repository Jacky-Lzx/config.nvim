return {
  {
    "mikavilpas/yazi.nvim",
    dependencies = { "folke/snacks.nvim" },
    -- stylua: ignore
    keys = {
      { "<leader>E",  "<CMD>Yazi<CR>",        desc = "[Yazi] open at the current file", mode = { "n", "v" }},
      { "<leader>cw", "<CMD>Yazi cwd<CR>",    desc = "[Yazi] open in working directory"             },
      { "<c-up>",     "<CMD>Yazi toggle<CR>", desc = "[Yazi] Resume the last session"                      },
    },
    ---@type YaziConfig | {}
    opts = {
      -- if you want to open yazi instead of netrw, see below for more info
      open_for_directories = false,
      -- open_multiple_tabs = true,
      keymaps = {
        show_help = "<f1>",
      },
    },
  },
}
