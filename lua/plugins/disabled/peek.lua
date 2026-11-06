return {
  {
    main = "peek",
    id = "peek.nvim",
    source = "toppair/peek.nvim",
    enabled = false, -- Requires deno when enabled.
    build = { "deno", "task", "--quiet", "build:fast" },
    opts = {},
    config = function(ctx)
      local opts = ctx.opts
      require("peek").setup(opts)
      vim.api.nvim_create_user_command("MarkdownPreview", require("peek").open, {})
    end,
  },
}
