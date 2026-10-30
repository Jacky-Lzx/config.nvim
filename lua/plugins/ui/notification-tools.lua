local notifications = require("integrations.notification_tools")

return {
  {
    -- Local-only until notification-tools has a published remote repository.
    dir = notifications.directory(),
    name = "notification-tools.nvim",
    main = "notification-tools",
    cond = notifications.available,
    lazy = false,
    priority = 1100,
    opts = {
      window = { border = "rounded", winblend = 0 },
      progress = { avoid = { "NvimTree", "TestExplorer" }, stale_timeout = 0 },
    },
    keys = {
      { "<leader>sn", "<Cmd>Notifications<CR>", desc = "[Notifications] History" },
      { "<leader>n", "<Cmd>Notifications<CR>", desc = "[Notifications] History" },
      { "<leader>un", "<Cmd>NotificationsDismiss<CR>", desc = "[Notifications] Dismiss" },
    },
  },
}
