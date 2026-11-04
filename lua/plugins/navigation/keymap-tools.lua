return {
  {
    dir = require("utils.platform").dev_plugin_root() .. "/keymap-tools.nvim",
    name = "keymap-tools.nvim",
    main = "keymap_tools",
    lazy = false,
    priority = 850,
    dependencies = { "selection-tools.nvim" },
    keys = {
      {
        "<leader>?",
        function()
          require("keymap_tools").pick()
        end,
        mode = { "n", "x" },
        desc = "Choose and execute buffer keymap",
      },
    },
    opts = {
      hints = { delay = 200 },
      window = { width = 80, height = 16, border = "rounded" },
    },
    config = function(_, opts)
      local keymaps = require("keymap_tools")
      keymaps.setup(opts)
      keymaps.register("config", {
        modes = { "n", "x", "o" },
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
