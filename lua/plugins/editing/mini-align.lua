return {
  {
    "echasnovski/mini.align",
    version = "*",
    keys = {
      { "gA", mode = { "n", "x" }, desc = "Align" },
      { "ga", mode = { "n", "x" }, desc = "Align with preview" },
    },
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
