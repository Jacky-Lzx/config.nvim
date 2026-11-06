local function focus_mode(mode)
  local focus = package.loaded["ui_tools.focus"]
  if focus then
    local state = focus.state()
    return state ~= nil and state.mode == mode
  end
end

local function indent_enabled()
  local indent = package.loaded["ui_tools.indent"]
  if indent then
    local render = package.loaded["ui_tools.render"]
    return indent.enabled == true or (render ~= nil and render.sources.indent ~= nil)
  end
end

local function dim_enabled()
  local focus = package.loaded["ui_tools.focus"]
  if focus then
    return focus.dimmed == true
  end
end

return {
  {
    id = "ui-tools.nvim",
    source = "Jacky-Lzx/ui-tools.nvim",
    version = "main",
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
      do
        require("keymap_tools").register("ui-tools.toggles", {
          toggles = {
            {
              keys = "<leader>Z",
              name = "Zen Mode",
              get = function()
                return focus_mode("zen")
              end,
            },
            {
              keys = "<leader>z",
              name = "Zoom",
              get = function()
                return focus_mode("zoom")
              end,
            },
            {
              keys = "<leader>tG",
              name = "Indent guides",
              get = indent_enabled,
            },
            {
              keys = "<leader>tD",
              name = "Scope dimming",
              get = dim_enabled,
            },
          },
        })
      end
      require("config.bindings").set("ui-tools.nvim", {
        {
          "<RightMouse>",
          function()
            require("ui_tools").menu({ mouse = true })
          end,
          mode = { "n", "x", "i" },
          desc = "[UI] Open context menu",
        },
        {
          "<2-RightMouse>",
          function()
            require("ui_tools").menu({ mouse = true })
          end,
          mode = { "n", "x", "i" },
          desc = "[UI] Open context menu",
        },
        {
          "<3-RightMouse>",
          function()
            require("ui_tools").menu({ mouse = true })
          end,
          mode = { "n", "x", "i" },
          desc = "[UI] Open context menu",
        },
        {
          "<4-RightMouse>",
          function()
            require("ui_tools").menu({ mouse = true })
          end,
          mode = { "n", "x", "i" },
          desc = "[UI] Open context menu",
        },
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
            require("features.toggles").notify("Zen Mode", focus_mode("zen"))
          end,
          desc = "[UI] Toggle Zen Mode",
        },
        {
          "<leader>z",
          function()
            require("ui_tools").zoom()
            require("features.toggles").notify("Zoom", focus_mode("zoom"))
          end,
          desc = "[UI] Toggle Zoom",
        },
        {
          "<leader>tG",
          function()
            require("ui_tools").toggle("indent")
            require("features.toggles").notify("Indent guides", indent_enabled())
          end,
          desc = "[UI] Toggle indent guides",
        },
        {
          "<leader>tD",
          function()
            require("ui_tools").dim()
            require("features.toggles").notify("Scope dimming", dim_enabled())
          end,
          desc = "[UI] Toggle scope dimming",
        },
      })
      local opts = ctx.opts
      require("ui_tools").setup(opts)
      require("features.toggles").scroll_bindings()
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
