return {
  {
    id = "completion-tools.nvim",
    -- The plugin is currently a local checkout; no unpublished remote fallback.
    dir = vim.fs.joinpath(require("utils.platform").dev_plugin_root(), "completion-tools.nvim"),
    main = "completion-tools",
    opts = require("integrations.completion").options(),
    config = function(ctx)
      local opts = ctx.opts
      require("completion_tools.bootstrap").setup(opts)
      require("integrations.completion").setup()
    end,
  },
}
