return {
  {
    id = "completion-tools.nvim",
    source = "git@github.com:Jacky-Lzx/completion-tools.nvim.git",
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
