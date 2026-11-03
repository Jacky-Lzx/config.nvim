-- completion-tools loads the native source on demand; command/status stay available.
return {
  {
    "zbirenbaum/copilot.lua",
    lazy = true,
    cmd = "Copilot",
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = { markdown = true, help = true },
    },
  },
  {
    "nvim-tree/nvim-web-devicons",
    optional = true,
    opts = { override = { copilot = { icon = "", color = "#cba6f7", name = "Copilot" } } },
  },
}
