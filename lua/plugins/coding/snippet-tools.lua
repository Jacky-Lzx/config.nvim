return {
  {
    dir = vim.fs.joinpath(require("utils.platform").dev_plugin_root(), "snippet-tools.nvim"),
    name = "snippet-tools.nvim",
    main = "snippet_tools",
    module = false,
    event = "InsertEnter",
    cmd = { "SnippetToolsInspect", "SnippetToolsStop", "SnippetToolsReload" },
    keys = {
      {
        "<A-l>",
        function()
          require("integrations.snippets").jump(1)
        end,
        mode = { "i", "s" },
        desc = "Snippet next field",
      },
      {
        "<A-h>",
        function()
          require("integrations.snippets").jump(-1)
        end,
        mode = { "i", "s" },
        desc = "Snippet previous field",
      },
      {
        "<A-j>",
        function()
          require("integrations.snippets").choice(1)
        end,
        mode = { "i", "s" },
        desc = "Snippet next choice",
      },
      {
        "<A-k>",
        function()
          require("integrations.snippets").choice(-1)
        end,
        mode = { "i", "s" },
        desc = "Snippet previous choice",
      },
      {
        "<A-c>",
        function()
          require("integrations.snippets").select_choice()
        end,
        mode = { "i", "s" },
        desc = "Snippet choice selection",
      },
    },
    init = function()
      require("integrations.snippets").setup()
    end,
    config = function()
      require("integrations.snippets").setup_native()
    end,
  },
}
