return {
  -- Show colors in the text: e.g. "#b3e2a7"
  {
    "norcalli/nvim-colorizer.lua",
    event = "BufRead",
    opts = {},
    main = "colorizer",
    config = function(_)
      require("colorizer").setup()
    end,
  },
}
