return {
  {
    dir = require("utils.platform").dev_plugin_root() .. "/debug-tools.nvim",
    name = "debug-tools.nvim",
    main = "debug_tools",
    lazy = false,
    priority = 1000,
    opts = { globals = true, override_print = true },
    config = function(_, opts)
      require("debug_tools").setup(opts)
      vim.api.nvim_create_user_command("StartupTime", function(args)
        local tries = args.args == "" and 10 or tonumber(args.args)
        local ok, err = pcall(function()
          assert(tries, "Expected a run count from 1 to 100")
          require("debug_tools.startuptime").run({ tries = tries })
        end)
        if not ok then
          vim.notify(tostring(err), vim.log.levels.ERROR)
        end
      end, { nargs = "?", desc = "Measure native Neovim startup (default: 10 runs)" })
    end,
  },
}
