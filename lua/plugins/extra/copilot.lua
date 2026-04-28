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
      sources = {
        default = { "copilot" },
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-copilot",
            score_offset = 100,
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
