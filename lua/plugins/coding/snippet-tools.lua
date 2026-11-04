return {
  {
    dir = vim.fs.joinpath(require("utils.platform").dev_plugin_root(), "snippet-tools.nvim"),
    name = "snippet-tools.nvim",
    main = "snippet_tools",
    module = false,
    event = "InsertEnter",
    cmd = { "SnippetToolsInspect", "SnippetToolsStop", "SnippetToolsReload" },
    init = function()
      require("integrations.snippets").setup()
    end,
    config = function()
      require("integrations.snippets").setup_native()
    end,
  },
}
