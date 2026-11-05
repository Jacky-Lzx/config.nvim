return {
  {
    id = "keymap-tools.nvim",
    dir = require("utils.platform").dev_plugin_root() .. "/keymap-tools.nvim",
    main = "keymap_tools",
    opts = {
      defer = true,
      hints = { delay = 200 },
      showkeys = { enabled = false, maxkeys = 5 },
      window = { width = 80, height = 16, border = "rounded" },
    },
    config = function(ctx)
      require("config.bindings").set("keymap-tools.nvim", {
        {
          "<leader>?",
          function()
            require("keymap_tools").pick()
          end,
          mode = { "n", "x" },
          desc = "Choose and execute buffer keymap",
        },
      })
      local opts = ctx.opts
      local keymaps = require("keymap_tools")
      keymaps.setup(opts)
      require("features.toggles").setup()
      require("integrations.diagnostic_toggles").setup()
      keymaps.register("config", {
        modes = { "n", "x", "o" },
        toggles = {
          {
            keys = "<A-z>",
            modes = { "n" },
            name = "Wrap",
            get = function(ctx)
              if ctx.win then
                return vim.api.nvim_get_option_value("wrap", { win = ctx.win })
              end
            end,
          },
        },
        groups = {
          { prefix = "<leader>tg", label = "[Git] Toggle" },
          { prefix = "<leader>gg", label = "[Git]" },
          { prefix = "<leader>cc", label = "[CodeCompanion]" },
          { prefix = "<leader>D", label = "[Dap]" },
          { prefix = "<leader>w", label = "[Workspace]" },
          { prefix = "<leader>s", label = "[Selection]" },
          { prefix = "<leader>t", label = "[Toggle]" },
          { prefix = "<leader>g", label = "[LSP] / [Git]" },
        },
      })
    end,
  },
}
