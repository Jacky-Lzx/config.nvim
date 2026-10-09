local M = {}

function M.requirements()
  return { { "mini.align", "lua/mini/align.lua" } }
end

function M.specs()
  return {
    {
      "nvim-mini/mini.align",
      version = "*",
      lazy = vim.g.config_plugin_install and true or false,
      opts = { mappings = { start = "gA", start_with_preview = "ga" } },
      config = function(_, opts)
        require("mini.align").setup(opts)
      end,
    },
  }
end

return M
