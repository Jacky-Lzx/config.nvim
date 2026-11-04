return {
  {
    -- The plugin is currently a local checkout; no unpublished remote fallback.
    dir = vim.fs.joinpath(require("utils.platform").dev_plugin_root(), "completion-tools.nvim"),
    name = "completion-tools.nvim",
    main = "completion-tools",
    module = false, -- Requiring capabilities must not trigger interactive setup.
    event = { "InsertEnter", "CmdlineEnter" },
    cmd = { "CompletionToolsCopilot", "CompletionToolsStatus" },
    init = function(plugin)
      -- Make the pure capability API available before the first input event.
      vim.opt.rtp:append(plugin.dir)
    end,
    opts = require("integrations.completion").options(),
    config = function(plugin, opts)
      -- Lazy adds the early runtime directory again; retain one entry.
      vim.opt.rtp:remove(plugin.dir)
      vim.opt.rtp:prepend(plugin.dir)
      require("completion-tools").setup(opts)
      require("integrations.completion").setup()
    end,
  },
}
