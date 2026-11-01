return {
  {
    dir = require("utils.platform").dev_plugin_root() .. "/ui-tools.nvim",
    name = "ui-tools.nvim",
    main = "ui_tools",
    lazy = false,
    priority = 900,
    opts = {
      indent = { only_scope = true, chunk = true },
      statuscolumn = { git_patterns = { "GitTools" } },
      guide = { columns = { 121 }, char = "" },
      feedback = { yank = true, hl = "IncSearch", timeout = 200 },
      focus = { width = 100, height = 0.9, dim = true },
      scrollbar = { handle = " ", blend = 100 },
    },
    config = function(_, opts)
      require("ui_tools").setup(opts)
      require("ui_tools.integrations.git_tools").setup()
    end,
    keys = {
      {
        "<leader><leader>",
        function()
          require("ui_tools").pulse()
        end,
        desc = "[UI] Pulse current line",
      },
      {
        "<leader>Z",
        function()
          require("ui_tools").zen()
        end,
        desc = "[UI] Toggle Zen Mode",
      },
      {
        "<leader>z",
        function()
          require("ui_tools").zoom()
        end,
        desc = "[UI] Toggle Zoom",
      },
      {
        "<leader>tG",
        function()
          require("ui_tools").toggle("indent")
        end,
        desc = "[UI] Toggle indent guides",
      },
      {
        "<leader>tD",
        function()
          require("ui_tools").dim()
        end,
        desc = "[UI] Toggle scope dimming",
      },
    },
  },
}
