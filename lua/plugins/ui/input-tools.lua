return {
  {
    "Jacky-Lzx/input-tools.nvim",
    dev = true,
    main = "input-tools",
    lazy = false,
    priority = 1000,
    opts = {
      status = false, -- Mode and position are already shown by ui-tools statusline.
      window = { row = 3 }, -- Top-centered command palette.
    },
  },
}
