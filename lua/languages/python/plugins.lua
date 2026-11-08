return {
  {
    id = "python-tools.nvim",
    source = "Jacky-Lzx/python-tools.nvim",
    version = "main",
    dev = true,
    mount = "on-demand",
    ft = { "python" },
    main = "python_tools",
    opts = {},
    config = function(ctx)
      require("config.bindings").set(
        "python-tools.nvim",
        { { "<leader>cv", "<CMD>VenvSelect<CR>", desc = "Select VirtualEnv", ft = "python" } }
      )
      require("integrations.python_environment").setup(ctx.opts)
    end,
  },
  "languages.python.debug",
}
