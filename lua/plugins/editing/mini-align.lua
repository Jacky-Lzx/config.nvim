return {
  {
    "echasnovski/mini.align",
    version = "*",
    event = "VeryLazy",
    opts = {
      mappings = {
        start = "gA",
        start_with_preview = "ga",
      },
    },
    config = function(_, opts)
      require("mini.align").setup(opts)
    end,
  },
}
