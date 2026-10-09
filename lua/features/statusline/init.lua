local M = {}

function M.requirements()
  return { { "lualine.nvim", "lua/lualine.lua" } }
end

function M.specs()
  return {
    {
      "nvim-lualine/lualine.nvim",
      event = "VeryLazy",
      dependencies = require("features.ui.icons").dependencies(),
      opts = function()
        local theme = require("config.plugins").status().features.theme.active
        local components = require("features.statusline.components")
        local macro_color = "Error"
        if theme then
          macro_color = { fg = "#333333", bg = require("catppuccin.palettes").get_palette("mocha").red }
        end
        return {
          options = {
            theme = theme and "catppuccin-nvim" or "auto",
            icons_enabled = require("features.ui.icons").available(),
            always_divide_middle = false,
            component_separators = { left = "", right = "" },
            section_separators = { left = "", right = "" },
          },
          sections = {
            lualine_a = { "mode" },
            lualine_b = {
              { components.branch, icon = "" },
              { "diff", source = components.diff },
              { "diagnostics", sources = { "nvim_diagnostic" } },
            },
            lualine_c = { "filename" },
            lualine_x = {
              { components.recording, color = macro_color, separator = { left = "", right = "" }, padding = 0 },
            },
            lualine_y = { "encoding", "fileformat", "filetype", "progress" },
            lualine_z = { "location" },
          },
          winbar = {
            lualine_a = { "filename" },
            lualine_b = {
              {
                function()
                  return " "
                end,
                color = "Comment",
              },
            },
            lualine_x = { "lsp_status" },
          },
          inactive_winbar = {
            lualine_b = {
              function()
                return " "
              end,
            },
          },
        }
      end,
    },
  }
end

return M
