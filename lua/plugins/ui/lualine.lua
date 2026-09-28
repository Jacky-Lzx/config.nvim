local features = require("config.selection").features

return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      { "AndreM222/copilot-lualine", enabled = features.ai == true },
    },
    event = "VeryLazy",
    opts = {
      options = {
        theme = "catppuccin-nvim",
        always_divide_middle = false,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { "filename" },
        lualine_x = {},
        lualine_y = { "encoding", "fileformat", "filetype", "progress" },
        lualine_z = { "location" },
      },
      -- stylua: ignore
      winbar = {
        lualine_a = { "filename", },
        lualine_b = { { function() return " " end, color = "Comment", }, },
        lualine_x = { "lsp_status", },
      },
      inactive_winbar = {
        -- Always show winbar
        -- stylua: ignore
        lualine_b = { function() return " " end, },
      },
    },
    config = function(_, opts)
      local mocha = require("catppuccin.palettes").get_palette("mocha")
      local overseer = require("lualine.component"):extend()
      function overseer:update_status(is_focused)
        if not package.loaded.overseer then
          return ""
        end
        self.component = self.component or require("lualine.components.overseer")(self.options)
        -- The outer component's draw() applies padding and resets task highlights.
        return self.component:update_status(is_focused)
      end

      local symbols
      local function trouble_symbols()
        if not package.loaded.trouble then
          return ""
        end
        symbols = symbols
          or require("trouble").statusline({
            mode = "lsp_document_symbols",
            groups = {},
            title = false,
            filter = { range = true },
            format = "{kind_icon}{symbol.name:Normal}",
          })
        return symbols.has() and symbols.get() or ""
      end

      local function show_macro_recording()
        local recording_register = vim.fn.reg_recording()
        if recording_register == "" then
          return ""
        else
          return "󰑋 " .. recording_register
        end
      end

      local macro_recording = {
        show_macro_recording,
        color = { fg = "#333333", bg = mocha.red },
        separator = { left = "", right = "" },
        padding = 0,
      }

      local copilot = {
        "copilot",
        show_colors = true,
        symbols = {
          status = {
            hl = {
              enabled = mocha.green,
              sleep = mocha.overlay0,
              disabled = mocha.surface0,
              warning = mocha.peach,
              unknown = mocha.red,
            },
          },
          spinner_color = mocha.mauve,
        },
      }

      table.insert(opts.sections.lualine_x, 1, macro_recording)
      if features.tasks then
        table.insert(opts.sections.lualine_x, 1, { overseer, component_name = "overseer" })
      end
      if features.ai then
        table.insert(opts.sections.lualine_c, copilot)
      end
      table.insert(opts.winbar.lualine_b, 1, {
        trouble_symbols,
      })

      require("lualine").setup(opts)
    end,
  },
}
