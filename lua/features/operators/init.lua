local M = {}

function M.requirements()
  return { { "mini.operators", "lua/mini/operators.lua" } }
end

function M.specs()
  return {
    {
      "nvim-mini/mini.operators",
      version = "*",
      lazy = vim.g.config_plugin_install and true or false,
      opts = { replace = { prefix = "cr" } },
      config = function(_, opts)
        require("mini.operators").setup(opts)
      end,
    },
  }
end

return M
