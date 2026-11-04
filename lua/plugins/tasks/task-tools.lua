return {
  {
    dir = require("utils.platform").dev_plugin_root() .. "/task-tools.nvim",
    name = "task-tools.nvim",
    main = "task_tools",
    init = function()
      require("keymap_tools").register("tasks", {
        groups = {
          { prefix = "<leader>m", label = "[Build]" },
          { prefix = "<leader>o", label = "[Tasks]" },
        },
      })
    end,
    cmd = {
      "TaskRun",
      "TaskShell",
      "TaskOpen",
      "TaskClose",
      "TaskToggle",
      "TaskStop",
      "TaskRerun",
      "TaskOutput",
      "TaskQuickfix",
      "TaskDelete",
      "TaskWatch",
      "TaskTerminal",
      "TaskSave",
      "TaskLoad",
    },
    -- stylua: ignore
    keys = {
      { "<leader>mc", function() require("features.tasks").prompt() end, desc = "[Build] Enter command" },
      { "<leader>mr", function() require("features.tasks").rerun() end, desc = "[Build] Run again" },
      { "<leader>ms", function() require("features.tasks").stop() end, desc = "[Build] Stop" },
      { "<leader>mo", function() require("features.tasks").output() end, desc = "[Build] Open output" },
      { "<leader>mq", function() require("features.tasks").quickfix() end, desc = "[Build] Export quickfix" },
      { "<F17>", "<cmd>TaskRun<cr>", desc = "[Tasks] Run" },
      { "<leader>or", "<cmd>TaskRun<cr>", desc = "[Tasks] Run" },
      { "<leader>ot", "<cmd>TaskToggle<cr>", desc = "[Tasks] Toggle list" },
      { "<leader>oa", function() require("features.tasks").run_file() end, desc = "[Tasks] Run file with arguments" },
      { "<leader>os", "<cmd>TaskStop<cr>", desc = "[Tasks] Stop latest" },
      { "<leader>oo", "<cmd>TaskOutput<cr>", desc = "[Tasks] Latest output" },
      { "<leader>oq", "<cmd>TaskQuickfix<cr>", desc = "[Tasks] Export latest quickfix" },
      { "<A-i>", function() require("task_tools").terminal() end, desc = "[Tasks] Toggle terminal", mode = { "n", "t" } },
    },
    opts = {
      python = function()
        return require("languages.python.interpreter").current()
      end,
      tasks = function(ctx)
        return require("features.tasks").definitions(ctx)
      end,
      terminal = { position = "float", width = 0.9, height = 0.9, border = "rounded" },
    },
  },
}
