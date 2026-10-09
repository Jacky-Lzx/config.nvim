local M = {}

function M.requirements()
  return { { "mini.comment", "lua/mini/comment.lua" } }
end

function M.specs()
  return {
    {
      "nvim-mini/mini.comment",
      lazy = vim.g.config_plugin_install and true or false,
      opts = {
        mappings = {
          comment = "gc",
          comment_line = "<leader>/",
          comment_visual = "<leader>/",
          textobject = "gc",
        },
      },
      config = function(_, opts)
        require("mini.comment").setup(opts)
      end,
    },
  }
end

return M
