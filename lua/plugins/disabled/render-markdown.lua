return {
  {
    main = "render-markdown",
    id = "render-markdown.nvim",
    enabled = false,
    source = "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "toolchain-tools.nvim",
    },
    opts = {
      file_types = { "markdown" },
      -- Disable by default, use keymap to toggle
      enabled = false,
      -- Clear native Tree-sitter conceal marks left behind before lazy loading.
      restart_highlighter = true,
      -- Use native LSP completions; no completion-engine-specific adapter.
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
    config = function(ctx)
      do
        require("keymap_tools").register("render-markdown", {
          toggles = {
            {
              keys = "<leader>tm",
              name = "Render Markdown",
              get = function()
                local state = package.loaded["render-markdown.state"]
                if state then
                  return state.enabled
                end
              end,
            },
          },
        })
      end
      require("config.bindings").set("render-markdown.nvim", {
        {
          "<leader>tm",
          function()
            require("render-markdown").toggle()
            require("features.toggles").notify("Render Markdown", require("render-markdown.state").enabled)
          end,
          desc = "Toggle render markdown",
        },
      })
      local opts = ctx.opts
      require("render-markdown").setup(opts)
    end,
  },
}
