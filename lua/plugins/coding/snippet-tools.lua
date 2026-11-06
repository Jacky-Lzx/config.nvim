return {
  {
    id = "snippet-tools.nvim",
    source = "Jacky-Lzx/snippet-tools.nvim",
    version = "main",
    dev = true,
    main = "snippet_tools",
    config = function(ctx)
      require("integrations.snippets").setup()
      require("config.bindings").set("snippet-tools.nvim", {
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
      })
      require("integrations.snippets").setup_native(ctx.opts, require("config.specs").project_root())
    end,
  },
}
