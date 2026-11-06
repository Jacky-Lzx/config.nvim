local hint_panels = {
  ui_tools_dashboard = true,
  ["file-tools"] = true,
  tasktools = true,
  tasktoolsoutput = true,
  toolchain = true,
  ["toolchain-versions"] = true,
  ["plugin-tools"] = true,
}

local function hint_filter(ctx)
  if ctx.buftype == "" then
    return true
  end
  return ctx.buftype == "nofile"
    and hint_panels[ctx.filetype] == true
    and ctx.mode == "n"
    and vim.keycode(ctx.prefix) == vim.keycode(vim.g.mapleader or "\\")
end

return {
  {
    id = "keymap-tools.nvim",
    source = "Jacky-Lzx/keymap-tools.nvim",
    version = "main",
    dev = true,
    main = "keymap_tools",
    dependencies = { "selection-tools.nvim" },
    opts = {
      defer = true,
      hints = { delay = 200, filter = hint_filter },
      showkeys = { enabled = false, maxkeys = 5 },
      window = { width = 80, height = 16, border = "rounded" },
    },
    config = function(ctx)
      require("config.bindings").set("keymap-tools.nvim", {
        {
          "<leader>sk",
          function()
            require("keymap_tools").pick()
          end,
          desc = "[Selection] Keymaps",
        },

        {
          "<C-/>",
          function()
            require("keymap_tools").pick()
          end,
          mode = { "n", "x", "i" },
          id = "keymaps.pick.universal",
          desc = "Choose and execute buffer keymap",
        },
        {
          "<C-_>",
          function()
            require("keymap_tools").pick()
          end,
          mode = { "n", "x", "i" },
          id = "keymaps.pick.legacy",
          desc = "Choose and execute buffer keymap",
        },
        {
          "<leader>?",
          function()
            require("keymap_tools").pick()
          end,
          mode = { "n", "x" },
          id = "keymaps.pick",
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
