local root = require("utils.platform").dev_plugin_root()

return {
  {
    dir = root .. "/theme-tools.nvim",
    name = "theme-tools.nvim",
    main = "theme_tools",
    lazy = false,
    priority = 800, -- Restore after Catppuccin and selection-tools initialize.
    dependencies = {
      { "catppuccin/nvim", name = "catppuccin" },
      { dir = root .. "/selection-tools.nvim", name = "selection-tools.nvim" },
    },
    opts = {
      default = "catppuccin-mocha",
      picker = { backend = "selection_tools" },
      themes = {
        "catppuccin-mocha",
        "catppuccin-latte",
        "catppuccin-frappe",
        "catppuccin-macchiato",
      },
    },
    keys = {
      { "<leader>ut", "<cmd>ThemeTools<cr>", desc = "[Theme] Preview themes" },
    },
  },
}
