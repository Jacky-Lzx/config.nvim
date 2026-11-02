-- The standalone command/status remain available. Completion suggestions wait
-- for a native source; the Blink-only adapter is intentionally not configured.
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
