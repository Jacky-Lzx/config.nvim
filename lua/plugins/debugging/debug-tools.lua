return {
  {
    id = "debug-tools.nvim",
    source = "Jacky-Lzx/debug-tools.nvim",
    version = "main",
    dev = true,
    main = "debug_tools",
    opts = { globals = true, override_print = true },
    config = function(ctx)
      local opts = ctx.opts
      require("debug_tools").setup(opts)
      vim.api.nvim_create_user_command("StartupTime", function(args)
        vim.api.nvim_cmd({ cmd = "DebugToolsStartup", args = args.fargs }, {})
      end, { nargs = "?", desc = "Alias for :DebugToolsStartup" })
    end,
  },
}
