return {
  {
    bootstrap = require("config.bindings").bootstrap("ui-tools.nvim", {
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
    }, function()
      local function focus_mode(mode)
        return function()
          local focus = package.loaded["ui_tools.focus"]
          if focus then
            local state = focus.state()
            return state ~= nil and state.mode == mode
          end
        end
      end
      require("keymap_tools").register("ui-tools.toggles", {
        toggles = {
          { keys = "<leader>Z", name = "Zen Mode", get = focus_mode("zen") },
          { keys = "<leader>z", name = "Zoom", get = focus_mode("zoom") },
          {
            keys = "<leader>tG",
            name = "Indent guides",
            get = function()
              local indent = package.loaded["ui_tools.indent"]
              if indent then
                local render = package.loaded["ui_tools.render"]
                return indent.enabled == true or (render ~= nil and render.sources.indent ~= nil)
              end
            end,
          },
          {
            keys = "<leader>tD",
            name = "Scope dimming",
            get = function()
              local focus = package.loaded["ui_tools.focus"]
              if focus then
                return focus.dimmed == true
              end
            end,
          },
        },
      })
    end),
    id = "ui-tools.nvim",
    source = "git@github.com:Jacky-Lzx/ui-tools.nvim.git",
    dev = true,
    main = "ui_tools",
    opts = {
      animate = { enabled = false },
      scroll = { enabled = false },
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
            key = "s",
            icon = " ",
            desc = "Restore Workspace",
            action = "WorkspaceRestore",
            enabled = function()
              return require("config.plugins").nodes()["workspace-tools.nvim"] ~= nil
            end,
          },
          { key = "L", icon = "󰒲 ", desc = "Plugins", action = "PluginTools" },
          { key = "q", icon = " ", desc = "Quit", action = "qa" },
        },
        footer = function()
          local manager = require("config.plugins").manager
          if not manager then
            return "Neovim"
          end
          return ("Neovim · %d plugins · %.2fms registration"):format(
            #manager.graph.order,
            manager.timings.resolve_ms + (manager.timings.start_ms or 0)
          )
        end,
      },
      bufferline = { numbers = true, auto_hide = 1, sidebar_filetypes = { ["file-tools"] = true } },
      statusline = {
        sections = require("features.bars").sections(),
        inactive_sections = { c = { { "filename", path = "tail" } } },
      },
      winbar = require("features.bars").winbar_options(),
      fold = { suffix = "  󰁂 %d" },
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
      colors = { style = "inline", symbol = "■" },
      todo = true,
    },
    config = function(ctx)
      local opts = ctx.opts
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
  },
}
