return {
  {
    "j-hui/fidget.nvim",
    -- lazy = true,
    event = "VeryLazy",
    opts = {
      notification = {
        window = {
          winblend = 0,
          border = "rounded",
          avoid = { "NvimTree", "TestExplorer" },
        },
      },
    },
  },
}
