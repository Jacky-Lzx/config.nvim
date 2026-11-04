return {
  {
    -- The plugin is currently a local checkout; no unpublished remote fallback.
    dir = vim.fs.joinpath(require("utils.platform").dev_plugin_root(), "completion-tools.nvim"),
    name = "completion-tools.nvim",
    main = "completion-tools",
    event = { "InsertEnter", "CmdlineEnter" },
    cmd = "CompletionToolsCopilot",
    opts = require("integrations.completion").options(),
    config = function(_, opts)
      require("completion-tools").setup(opts)
      require("integrations.completion").setup()
    end,
  },
}
