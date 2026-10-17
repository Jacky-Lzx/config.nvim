return {
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
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
