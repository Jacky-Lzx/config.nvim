return {
  {
    config = function(ctx)
      require("config.bindings").set("notification-tools.nvim", {
        { "<leader>N", "<Cmd>Notifications<CR>", desc = "[Notifications] History" },
        { "<leader>sN", "<Cmd>NotificationsPick<CR>", desc = "[Notifications] Search history" },
        { "<leader>sn", "<Cmd>Notifications<CR>", desc = "[Notifications] History" },
        { "<leader>n", "<Cmd>Notifications<CR>", desc = "[Notifications] History" },
        { "<leader>un", "<Cmd>NotificationsDismiss<CR>", desc = "[Notifications] Dismiss" },
      })
      require("notification-tools").setup(ctx.opts)
    end,
    id = "notification-tools.nvim",
    source = "Jacky-Lzx/notification-tools.nvim",
    dev = true,
    main = "notification-tools",
    opts = {
      messages = { enabled = true, routes = { bufwrite = "drop" } },
      notification = {
        filter = function(notice)
          -- Older native write messages use progress or an unnamed kind.
          if
            notice.source == "neovim"
            and notice.level < vim.log.levels.WARN
            and notice.message:match('^%s*".-"%s+.-%d+L,%s*%d+B%s+written%s*$')
          then
            return "drop"
          end
        end,
      },
      window = { border = "rounded", winblend = 0 },
      progress = { avoid = { "file-tools", "TestExplorer" }, stale_timeout = 0 },
    },
  },
}
