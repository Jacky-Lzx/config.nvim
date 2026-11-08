return {
  {
    config = function(ctx)
      do
        require("keymap_tools").register("tasks", {
          groups = {
            { prefix = "<leader>m", label = "[Build]" },
            { prefix = "<leader>o", label = "[Tasks]" },
          },
        })
      end
      require("config.bindings").set("task-tools.nvim", {
        {
          "<leader>mc",
          function()
            require("features.tasks").prompt()
          end,
          desc = "[Build] Enter command",
        },
        {
          "<leader>mr",
          function()
            require("features.tasks").rerun()
          end,
          desc = "[Build] Run again",
        },
        {
          "<leader>ms",
          function()
            require("features.tasks").stop()
          end,
          desc = "[Build] Stop",
        },
        {
          "<leader>mo",
          function()
            require("features.tasks").output()
          end,
          desc = "[Build] Open output",
        },
        {
          "<leader>mq",
          function()
            require("features.tasks").quickfix()
          end,
          desc = "[Build] Export quickfix",
        },
        { "<F17>", "<cmd>TaskRun<cr>", desc = "[Tasks] Run" },
        { "<leader>or", "<cmd>TaskRun<cr>", desc = "[Tasks] Run" },
        require("features.toggles").binding("tasks.list", "<cmd>TaskToggle<cr>"),
        {
          "<leader>oa",
          function()
            require("features.tasks").run_file()
          end,
          desc = "[Tasks] Run file with arguments",
        },
        { "<leader>os", "<cmd>TaskStop<cr>", desc = "[Tasks] Stop latest" },
        { "<leader>oo", "<cmd>TaskOutput<cr>", desc = "[Tasks] Latest output" },
        {
          "<leader>oO",
          function()
            local ok, err = require("task_tools.integrations.notification_tools").open_last_output()
            if not ok and err then
              vim.notify(err, vim.log.levels.WARN, { title = "Tasks" })
            end
          end,
          desc = "[Tasks] Last finished output",
        },
        { "<leader>oq", "<cmd>TaskQuickfix<cr>", desc = "[Tasks] Export latest quickfix" },
        {
          require("config.toggle_keys").get("tasks.terminal").lhs,
          function()
            require("task_tools").terminal()
          end,
          desc = "[Tasks] Toggle terminal",
          mode = "n",
        },
      })
      require("task_tools").setup(ctx.opts)
      require("task_tools.integrations.notification_tools").setup()
    end,
    id = "task-tools.nvim",
    dependencies = { { id = "notification-tools.nvim", optional = true } },
    source = "Jacky-Lzx/task-tools.nvim",
    version = "main",
    dev = true,
    main = "task_tools",
    opts = {
      forward_osc133 = true,
      python = function(ctx)
        return require("languages.python.interpreter").current(ctx and { buf = ctx.buf } or nil)
      end,
      python_env = function(ctx)
        return require("languages.python.interpreter").environment(ctx and { buf = ctx.buf } or nil)
      end,
      tasks = function(ctx)
        return require("features.tasks").definitions(ctx)
      end,
      terminal = { position = "float", width = 0.9, height = 0.9, border = "rounded" },
    },
  },
}
