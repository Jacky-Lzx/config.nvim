return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },

    opts = {
      -- keymap-tools owns Normal/Visual hints and the global keymap picker.
      -- Retain operator-pending textobject hints used by mini.ai and LaTeX.
      triggers = { { "<auto>", mode = "o" } },
      plugins = { marks = false, registers = false, spelling = { enabled = false } },
      preset = "helix",
      defer = function(ctx)
        return false
      end,
      win = {
        -- no_overlap = true,
        title = false,
        width = 0.5,
      },
      -- stylua: ignore
      spec = {
        { "<leader>tg", group = "[Git] Toggle"                },
        { "<leader>gg", group = "[Git]"                       },
        { "<leader>cc", group = "[CodeCompanion]", icon = "" },
        { "<leader>D",  group = "[Dap]",           icon = "" },
        { "<leader>w",  group = "[Workspace]"                 },
        { "<leader>s",  group = "[Snacks]"                    },
        { "<leader>t",  group = "[Snacks] Toggle"             },
        { "<leader>g",  group = "[LSP] / [Git]"           },

        { "]c", desc = "Jump to next change"     },
        { "[c", desc = "Jump to previous change" },
      },

      replace = {
        desc = {
          { "<Plug>%(?(.*)%)?", "%1" },
          { "<plug>%(?(.*)%)?", "%1" },
          { "^%+", "" },
          { "<[cC]md>", "" },
          { "<[cC][rR]>", "" },
          { "<[sS]ilent>", "" },
          { "^lua%s+", "" },
          { "^call%s+", "" },
          { "^:%s*", "" },
        },
      },
      -- expand all nodes wighout a description
      expand = function(node)
        return not node.desc
      end,
    },
    opts_extend = { "spec" },
  },
}
