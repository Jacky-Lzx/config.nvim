return {
  {
    "Jacky-Lzx/ui-tools.nvim",
    url = "git@github.com:Jacky-Lzx/ui-tools.nvim.git",
    dev = true,
    name = "ui-tools.nvim",
    main = "ui_tools",
    lazy = false,
    priority = 900,
    opts = {
      indent = { only_scope = true, chunk = false },
      statuscolumn = {
        slot_width = 1,
        separator = " ",
        git_numbers = true,
        folds = { levels = true, columns = 2, scope = true },
        layout = { "diagnostic", { "sign", "mark" }, "number", "fold" },
        git_patterns = { "GitTools" },
      },
      guide = { columns = { 121 }, char = "" },
      feedback = { yank = true, hl = "IncSearch", timeout = 200 },
      focus = { width = 100, height = 0.9, dim = true },
      scrollbar = { handle = " ", blend = 100, cursor = true, cursor_char = "●" },
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
