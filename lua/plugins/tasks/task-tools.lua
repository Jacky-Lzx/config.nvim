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
          id = "tasks.prompt",
          desc = "[Build] Enter command",
        },
        {
          "<leader>mr",
          function()
            require("features.tasks").rerun()
          end,
          id = "tasks.rerun",
          desc = "[Build] Run again",
        },
        {
          "<leader>ms",
          function()
            require("features.tasks").stop()
          end,
          id = "tasks.stop_build",
          desc = "[Build] Stop",
        },
        {
          "<leader>mo",
          function()
            require("features.tasks").output()
          end,
          id = "tasks.build_output",
          desc = "[Build] Open output",
        },
        {
          "<leader>mq",
          function()
            require("features.tasks").quickfix()
          end,
          id = "tasks.build_quickfix",
          desc = "[Build] Export quickfix",
        },
        { "<F17>", "<cmd>TaskRun<cr>", desc = "[Tasks] Run" },
        { "<leader>or", "<cmd>TaskRun<cr>", id = "tasks.select", desc = "[Tasks] Run" },
        { "<leader>ot", "<cmd>TaskToggle<cr>", id = "tasks.list", desc = "[Tasks] Toggle list" },
        {
          "<leader>oa",
          function()
            require("features.tasks").run_file()
          end,
          id = "tasks.run_file",
          desc = "[Tasks] Run file with arguments",
        },
        { "<leader>os", "<cmd>TaskStop<cr>", desc = "[Tasks] Stop latest" },
        { "<leader>oo", "<cmd>TaskOutput<cr>", desc = "[Tasks] Latest output" },
        { "<leader>oq", "<cmd>TaskQuickfix<cr>", desc = "[Tasks] Export latest quickfix" },
        {
          "<A-i>",
          function()
            require("task_tools").terminal()
          end,
          id = "tasks.terminal",
          desc = "[Tasks] Toggle terminal",
          mode = { "n", "t" },
        },
      })
      require("task_tools").setup(ctx.opts)
    end,
    id = "task-tools.nvim",
    source = "Jacky-Lzx/task-tools.nvim",
    version = "main",
    dev = true,
    main = "task_tools",
    opts = {
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
