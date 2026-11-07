return {
  {
    main = "peek",
    id = "peek.nvim",
    source = "toppair/peek.nvim",
    enabled = true,
    mount = "on-demand",
    ft = { "markdown" }, -- Requires deno and the configured build task.
    build = { "deno", "task", "--quiet", "build:fast" },
    opts = {},
    config = function(ctx)
      local opts = ctx.opts
      require("peek").setup(opts)
      vim.api.nvim_create_user_command("MarkdownPreview", require("peek").open, {})
    end,
  },
}
