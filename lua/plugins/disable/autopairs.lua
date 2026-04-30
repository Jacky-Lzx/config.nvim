return {
  {
    "windwp/nvim-autopairs",
    enabled = false,
    event = "InsertEnter",
    opts = {
      ignored_next_char = "[%w%.]", -- will ignore alphanumeric and `.` symbol
    },
  },
}
