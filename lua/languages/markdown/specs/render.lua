return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    keys = {
      { "<leader>tm", desc = "Enable render markdown" },
    },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons", -- if you prefer nvim-web-devicons
    },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      -- Disable by default, use keymap to toggle
      enabled = false,
      -- The plugin also provides a completion method using blink.cmp
      -- However, just enabling the general LSP conmpletions is enough
      completions = {
        lsp = { enabled = true },
      },
      -- Vim modes that will show a rendered view of the markdown file, :h mode(), for all enabled
      -- components. Individual components can be enabled for other modes. Remaining modes will be
      -- unaffected by this plugin.
      -- Default: render_modes = { "n", "c", "t" },
      -- Set to true to enable render in all modes
      render_modes = true,
      checkbox = {
        checked = { scope_highlight = "@markup.strikethrough" },
      },
      indent = {
        enabled = true,
        skip_heading = true,
      },
      latex = { enabled = false },

      code = {
        -- Disable the sign shown on the left of the line numbers
        sign = false,
      },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)

      require("snacks")
        .toggle({
          name = "Render Markdown",
          get = function()
            return require("render-markdown.state").enabled
          end,
          set = function(enabled)
            local m = require("render-markdown")
            if enabled then
              m.enable()
            else
              m.disable()
            end
          end,
        })
        :map("<leader>tm")
    end,
  },
}
