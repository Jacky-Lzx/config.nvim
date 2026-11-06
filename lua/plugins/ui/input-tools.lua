return {
  {
    id = "input-tools.nvim",
    source = "Jacky-Lzx/input-tools.nvim",
    version = "main",
    dev = true,
    main = "input-tools",
    opts = {
      status = false, -- Mode and position are already shown by ui-tools statusline.
      window = { row = 3 }, -- Top-centered command palette.
    },
  },
}
