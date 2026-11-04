-- Completion and authentication are owned by completion-tools.nvim.
return {
  {
    "nvim-tree/nvim-web-devicons",
    optional = true,
    opts = { override = { copilot = { icon = "", color = "#cba6f7", name = "Copilot" } } },
  },
}
