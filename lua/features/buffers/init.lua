local M = {}

function M.requirements()
  return { { "barbar.nvim", "lua/barbar.lua" } }
end

function M.specs()
  return {
    {
      "romgrk/barbar.nvim",
      version = "^1.0.0",
      event = "VeryLazy",
      dependencies = require("features.ui.icons").dependencies(),
      init = function()
        vim.g.barbar_auto_setup = false
      end,
      keys = require("features.buffers.keymaps").get(),
      opts = {
        animation = false,
        auto_hide = 1,
        sidebar_filetypes = {},
        icons = { filetype = { enabled = require("features.ui.icons").available() } },
      },
      config = function(_, opts)
        vim.o.showtabline = 2
        require("barbar").setup(opts)
      end,
    },
  }
end

return M
