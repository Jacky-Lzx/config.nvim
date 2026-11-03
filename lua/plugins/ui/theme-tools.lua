local root = require("utils.platform").dev_plugin_root()

return {
  {
    dir = root .. "/theme-tools.nvim",
    name = "theme-tools.nvim",
    main = "theme_tools",
    lazy = false,
    priority = 800, -- Restore after selection-tools initializes.
    dependencies = {
      { dir = root .. "/selection-tools.nvim", name = "selection-tools.nvim" },
    },
    opts = {
      catppuccin = {
        transparent_background = true,
        float = {
          transparent = true, -- enable transparent floating windows
        },
        flavour = "mocha",
        integrations = {
          barbar = true,
          flash = true,
          gitsigns = true,
          markdown = true,
          mason = true,
          noice = true,
          copilot_vim = true,
          dap = true,
          dap_ui = true,
          native_lsp = {
            enabled = true,
            virtual_text = {
              errors = { "italic" },
              hints = { "italic" },
              warnings = { "italic" },
              information = { "italic" },
              ok = { "italic" },
            },
            underlines = {
              errors = { "underline" },
              hints = { "underline" },
              warnings = { "underline" },
              information = { "underline" },
              ok = { "underline" },
            },
            inlay_hints = {
              background = true,
            },
          },
          nvim_surround = true,
          treesitter = true,
          treesitter_context = true,
          overseer = true,
          rainbow_delimiters = true,
          render_markdown = true,
          snacks = {
            enabled = true,
          },
          which_key = true,
        },
      },
      default = "catppuccin-mocha",
      picker = { backend = "selection_tools" },
      themes = {
        "catppuccin-mocha",
        "catppuccin-latte",
        "catppuccin-frappe",
        "catppuccin-macchiato",
      },
    },
    config = function(_, opts)
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("lzx_highlights", { clear = true }),
        pattern = "catppuccin*",
        callback = function()
          require("config.highlights").apply()
        end,
      })
      require("theme_tools").setup(opts)
    end,
    keys = {
      { "<leader>ut", "<cmd>ThemeTools<cr>", desc = "[Theme] Preview themes" },
    },
  },
}
