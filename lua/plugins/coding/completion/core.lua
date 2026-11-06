return {
  {
    id = "completion-tools.nvim",
    dependencies = { "snippet-tools.nvim", "pairs.nvim" },
    source = "Jacky-Lzx/completion-tools.nvim",
    version = "main",
    dev = true,
    main = "completion-tools",
    opts = require("integrations.completion").options(),
    config = function(ctx)
      local opts = ctx.opts
      require("completion_tools.bootstrap").setup(opts)
      require("integrations.completion").setup()
    end,
  },
}
