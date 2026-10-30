return {
  {
    "Jacky-Lzx/notification-tools.nvim",
    url = "git@github.com:Jacky-Lzx/notification-tools.nvim.git",
    dev = true,
    main = "notification-tools",
    lazy = false,
    priority = 1100,
    opts = {
      messages = { enabled = true },
      window = { border = "rounded", winblend = 0 },
      progress = { avoid = { "NvimTree", "TestExplorer" }, stale_timeout = 0 },
    },
    keys = {
      { "<leader>N", "<Cmd>Notifications<CR>", desc = "[Notifications] History" },
      { "<leader>sN", "<Cmd>Notifications<CR>", desc = "[Notifications] History" },
      { "<leader>sn", "<Cmd>Notifications<CR>", desc = "[Notifications] History" },
      { "<leader>n", "<Cmd>Notifications<CR>", desc = "[Notifications] History" },
      { "<leader>un", "<Cmd>NotificationsDismiss<CR>", desc = "[Notifications] Dismiss" },
    },
  },
}
