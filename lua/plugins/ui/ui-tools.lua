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
      dashboard = {
        layout = "vertical", -- "horizontal" places the art to the left; both fit automatically.
        header = [[
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⠀⠀⠀⠀⠀⠀⠸⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡇⠀⠀⠀⠀⠀⠀⢻⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣷⠀⠀⠀⠀⠀⠀⠘⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣧⠀⠀⠀⠀⠀⠀⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣆⠀⠀⠀⠀⠀⢹⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣿⣿⣧⡀⠀⠀⠀⢸⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡀⠀⠀⠀⢹⣿⣿⣿⣷⣄⠀⠀⣸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⢄⣄⠀⠀⠀⠀⠀⠀⠀⠀⠸⣾⣿⣄⠀⠀⠀⢻⣿⣿⡿⢿⣿⣶⣾⣿⠟⠙⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⡀⠀⠀⠀⠻⣿⡇⠀⠙⣿⣿⣿⠀⢠⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠁⠀⠀⠀⠀⠘⢿⣦⣤⣽⣿⣿⣶⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⡇⠀⠀⠀⢀⣀⣠⣤⣤⣤⣄⣰⣿⡟⠀⠀⠀⠀⠀⢀⡀⢽⠿⠿⠛⠛⠛⠂⠒⢠⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⣿⣔⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠡⣈⠀⡁⠀⡁⢈⠀⡡⠚⠁⢀⠤⠠⠐⠢⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢨⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠛⠻⣇⠀⠀⠀⠀⠀⠀⠀⡷⠀⠂⠐⠠⣺⠀⠀⠀⠀⡀⠠⠄⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⡿⠁⠀⠀⠹⣿⣿⣿⠀⠀⠀⢻⠀⠀⠀⠀⠀⠀⠀⣏⠀⡁⢈⠀⡻⠀⡀⠀⠀⠁⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣿⣿⡀⠀⠀⢠⣿⣿⣿⣦⣀⣠⣿⠀⠀⠀⠀⠀⠀⠀⡧⠀⠄⠠⠈⠄⡀⢃⠀⠀⠀⠀⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⣿⣿⣷⣾⣿⣿⣿⣿⣿⣿⡿⠃⢀⡀⠀⠀⠀⠀⢀⢱⡄⠂⠐⠀⠂⢹⡿⠦⠤⠤⠌⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⡿⠿⠿⠿⠿⠛⢫⠁⠀⡠⠃⠀⠅⠀⠀⠀⡌⣼⡇⡁⢈⠠⡙⠌⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⠃⠀⠀⠀⡒⠂⠀⠁⠀⠉⠀⠁⠀⠀⢀⠜⢤⣿⠃⠄⠠⠘⠀⠂⠘⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⡃⠸⠀⠃⣿⠟⠄⠀⠄⠣⡀⠀⠀⠀⡠⡁⡁⣾⡟⡁⠀⡁⣬⣤⢽⣬⠀⡀⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠔⣱⢀⠂⠀⠀⣷⣶⣔⣶⣧⠸⣉⣢⣀⡴⠁⢄⣼⡿⠐⠀⠂⣰⣿⣿⣿⣿⣀⣄⣠⣉⠦⠤⠤⠄⠀⠤⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠈⠉⠉⠉⠉⠉⠉⠉⠉⠐⠂⠦⠊⠙⣿⡿⣿⠏⠁⠃⠀⠀⠈⠑⠛⠉⠁⠚⠒⠉⠀⢻⣿⣸⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠁⢣⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
          ]],
        keys = {
          {
            key = "f",
            icon = " ",
            desc = "Find File",
            action = function()
              require("selection_tools").files()
            end,
          },
          { key = "n", icon = " ", desc = "New File", action = "enew | startinsert" },
          {
            key = "g",
            icon = " ",
            desc = "Find Text",
            action = function()
              require("selection_tools").grep({ regex = true })
            end,
          },
          {
            key = "r",
            icon = " ",
            desc = "Recent Files",
            action = function()
              require("selection_tools").recent()
            end,
          },
          {
            key = "c",
            icon = " ",
            desc = "Config",
            action = function()
              require("selection_tools").files({ cwd = vim.fn.stdpath("config") })
            end,
          },
          {
            key = "s",
            icon = " ",
            desc = "Restore Session",
            action = "AutoSession restore",
            enabled = function()
              return require("lazy.core.config").plugins["auto-session"] ~= nil
            end,
          },
          { key = "L", icon = "󰒲 ", desc = "Lazy", action = "Lazy" },
          { key = "q", icon = " ", desc = "Quit", action = "qa" },
        },
        footer = function()
          local stats = require("lazy.stats").stats()
          return ("Neovim loaded %d/%d plugins in %.2fms"):format(stats.loaded, stats.count, stats.startuptime)
        end,
      },
      bufferline = { numbers = true, auto_hide = 1, sidebar_filetypes = { NvimTree = true } },
      statusline = {
        sections = require("features.bars").sections(),
        inactive_sections = { c = { { "filename", path = "tail" } } },
      },
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
      context_menu = true,
    },
    config = function(_, opts)
      require("ui_tools").setup(opts)
      require("features.bars").setup()
      require("ui_tools.integrations.git_tools").setup()
      require("ui_tools.integrations.context_lsp").setup({
        actions = {
          definition = function()
            require("lsp-tools").lsp_definitions()
          end,
          references = function()
            require("lsp-tools").lsp_references()
          end,
          hover = function()
            require("lsp-tools").hover()
          end,
          rename = function()
            require("lsp-tools").rename()
          end,
          code_action = function()
            require("lsp-tools").code_action()
          end,
          diagnostic = function()
            require("lsp-tools").diagnostic()
          end,
        },
        shortcuts = {
          definition = "gd",
          references = "gi",
          hover = "<leader>gH",
          rename = "<leader>rn",
          code_action = "<leader>a",
          diagnostic = "<leader>d",
        },
      })
    end,
    keys = {
      {
        "<A-S-,>",
        function()
          require("ui_tools.bufferline").move(-1)
        end,
        desc = "[Buffer] Move buffer left",
      },
      {
        "<A-S-.>",
        function()
          require("ui_tools.bufferline").move(1)
        end,
        desc = "[Buffer] Move buffer right",
      },
      {
        "<A-<>",
        function()
          require("ui_tools.bufferline").move(-1)
        end,
        desc = "[Buffer] Move buffer left",
      },
      {
        "<A->>",
        function()
          require("ui_tools.bufferline").move(1)
        end,
        desc = "[Buffer] Move buffer right",
      },
      {
        "<A-1>",
        function()
          require("ui_tools.bufferline").go(1)
        end,
        desc = "[Buffer] Go to buffer 1",
      },
      {
        "<A-2>",
        function()
          require("ui_tools.bufferline").go(2)
        end,
        desc = "[Buffer] Go to buffer 2",
      },
      {
        "<A-3>",
        function()
          require("ui_tools.bufferline").go(3)
        end,
        desc = "[Buffer] Go to buffer 3",
      },
      {
        "<A-4>",
        function()
          require("ui_tools.bufferline").go(4)
        end,
        desc = "[Buffer] Go to buffer 4",
      },
      {
        "<A-5>",
        function()
          require("ui_tools.bufferline").go(5)
        end,
        desc = "[Buffer] Go to buffer 5",
      },
      {
        "<A-6>",
        function()
          require("ui_tools.bufferline").go(6)
        end,
        desc = "[Buffer] Go to buffer 6",
      },
      {
        "<A-7>",
        function()
          require("ui_tools.bufferline").go(7)
        end,
        desc = "[Buffer] Go to buffer 7",
      },
      {
        "<A-8>",
        function()
          require("ui_tools.bufferline").go(8)
        end,
        desc = "[Buffer] Go to buffer 8",
      },
      {
        "<A-9>",
        function()
          require("ui_tools.bufferline").go(9)
        end,
        desc = "[Buffer] Go to buffer 9",
      },
      {
        "<A-h>",
        function()
          require("ui_tools.bufferline").cycle(-1)
        end,
        desc = "[Buffer] Previous buffer",
      },
      {
        "<A-l>",
        function()
          require("ui_tools.bufferline").cycle(1)
        end,
        desc = "[Buffer] Next buffer",
      },
      {
        "[b",
        function()
          require("ui_tools.bufferline").cycle(-1)
        end,
        desc = "[Buffer] Previous buffer",
      },
      {
        "]b",
        function()
          require("ui_tools.bufferline").cycle(1)
        end,
        desc = "[Buffer] Next buffer",
      },
      {
        "<A-w>",
        function()
          require("features.bars").close()
        end,
        desc = "Close buffer",
      },
      {
        "<A-u>",
        function()
          require("features.bars").restore()
        end,
        desc = "Restore buffer",
      },
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
