return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      transparent_background = true,
      float = {
        transparent = true, -- enable transparent floating windows
      },
      -- flavour = "mocha"
      integrations = {
        barbar = true,
        blink_cmp = true,
        fidget = true,
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
          indent_scope_color = "flamingo", -- catppuccin color (eg. `lavender`) Default: text
        },
        lsp_trouble = true,
        which_key = true,
      },
      custom_highlights = function(colors)
          -- stylua: ignore
          return {
            -- Comment                  = { fg = colors.flamingo },
            -- TabLineSel               = { bg = colors.pink     },
            -- CmpBorder                = { fg = colors.surface2 },
            -- Pmenu                    = { bg = colors.none     },
            LineNr                      = { fg = colors.surface2 },
            -- Search                   = { bg = colors.flamingo },
            Visual                      = { bg = colors.overlay0 },
            Search                      = { bg = colors.surface2 },
            IncSearch                   = { bg = colors.mauve },
            CurSearch                   = { bg = colors.mauve },
            -- CursorLine               = { bg = colors.falmingo }
            LspSignatureActiveParameter = { bg = colors.overlay0 },
            MatchParen                  = { bg = colors.mauve, fg = colors.base, bold = true},
          }
      end,
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)

      vim.cmd([[colorscheme catppuccin-mocha]])
    end,
  },
}
