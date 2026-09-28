return {
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = {
      "fang2hou/blink-copilot",
      {
        "zbirenbaum/copilot.lua",
        event = "VeryLazy",
        opts = {
          suggestion = {
            enabled = false,
          },
          panel = {
            enabled = false,
          },
          filetypes = {
            markdown = true,
            help = true,
          },
        },
      },
    },
    opts = {
      keymap = {
        ["<A-i>"] = {
          --- Toggle copilot suggestions
          function(cmp)
            if not vim.b.blink_sources then
              vim.b.blink_sources = require("blink.cmp.config").sources.default
            end

            local sources = vim.b.blink_sources

            if vim.tbl_contains(sources, "copilot") then
              sources = vim.tbl_filter(function(source)
                return source ~= "copilot"
              end, sources)
            else
              table.insert(sources, 1, "copilot")
            end

            cmp.show({ providers = sources })

            vim.b.blink_sources = sources
          end,
        },
      },
      sources = {
        default = { "copilot" },
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-copilot",
            score_offset = 90,
            async = true,
            opts = {
              kind_icon = "",
              kind_hl = "DevIconCopilot",
            },
          },
        },
      },
    },
  },

  -- Customization of the Copilot icon
  {
    "nvim-tree/nvim-web-devicons",
    optional = true,
    opts = {
      override = {
        copilot = {
          icon = "",
          color = "#cba6f7", -- Catppuccin.mocha.mauve
          name = "Copilot",
        },
      },
    },
  },
}
