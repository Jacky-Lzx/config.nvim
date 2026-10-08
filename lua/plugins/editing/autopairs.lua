return {
  {
    "windwp/nvim-autopairs",
    cond = false,
    event = "InsertEnter",
    opts = {
      ignored_next_char = "[%w%.]", -- will ignore alphanumeric and `.` symbol
    },
  },
}
