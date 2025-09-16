return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },

    keys = {
      -- stylua: ignore
      { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "[Which-key] Buffer Local Keymaps", },
    },

    opts = {
      ---@type false | "classic" | "modern" | "helix"
      preset = "helix",
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
        { "<leader>g",  group = "[Trouble] / [Git]"           },
      },
      -- expand all nodes wighout a description
      expand = function(node)
        return not node.desc
      end,
    },
    opts_extend = { "spec" },
  },
}
