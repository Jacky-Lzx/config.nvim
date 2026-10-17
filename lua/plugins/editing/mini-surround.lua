return {
  {
    "echasnovski/mini.surround",
    version = "*",
    keys = {
      -- Disable the vanilla `s` keybinding
      { "s", "<NOP>", mode = { "n", "x", "o" } },
      { "sa", mode = { "n", "x" }, desc = "Add surrounding" },
      { "sr", desc = "Replace surrounding" },
      { "sd", desc = "Delete surrounding" },
      { "sf", desc = "Find surrounding right" },
      { "sF", desc = "Find surrounding left" },
      { "sh", desc = "Highlight surrounding" },
      { "sn", desc = "Update surrounding search range" },
    },
    config = true,
  },
}
