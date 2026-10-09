local M = {}

function M.requirements()
  return { { "catppuccin", "lua/catppuccin/init.lua" } }
end

function M.specs()
  return {
    {
      "catppuccin/nvim",
      name = "catppuccin",
      lazy = vim.g.config_plugin_install and true or false,
      priority = 1000,
      opts = function()
        local features = require("config.plugins").status().features
        return {
          flavour = "mocha",
          transparent_background = true,
          float = { transparent = true },
          auto_integrations = false,
          integrations = {
            gitsigns = features.git.active,
            barbar = features.buffers.active,
            blink_cmp = { enabled = features.input.active, style = "bordered" },
            snacks = { enabled = features.picker.active, indent_scope_color = "flamingo" },
          },
          custom_highlights = require("features.theme.highlights").get,
        }
      end,
      config = function(_, opts)
        require("catppuccin").setup(opts)
        vim.cmd.colorscheme("catppuccin-nvim")
      end,
    },
  }
end

return M
