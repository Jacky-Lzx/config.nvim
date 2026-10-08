return {
  {
    "echasnovski/mini.surround",
    version = "*",
    event = "VeryLazy",
    keys = {
      -- Disable the vanilla `s` keybinding
      { "s", "<NOP>", mode = { "n", "x", "o" } },
      { "sa", mode = { "n", "x", "o" } },
      { "sr", mode = { "n", "x", "o" } },
      { "sd", mode = { "n", "x", "o" } },
    },
    config = true,
  },
}
