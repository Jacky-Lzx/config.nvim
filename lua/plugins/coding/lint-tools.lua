return {
  {
    id = "lint-tools.nvim",
    main = "lint_tools",
    enabled = true,
    -- Local checkout until this new plugin has a published source.
    dir = vim.fs.joinpath(require("utils.platform").dev_plugin_root(), "lint-tools.nvim"),
    after = { "toolchain-tools.nvim" },
    dependencies = { "toolchain-tools.nvim" },
    opts = {
      linters = vim.tbl_deep_extend("force", require("languages").current().linter_options, {
        codespell = {
          condition = function(ctx)
            return #vim.lsp.get_clients({ bufnr = ctx.bufnr, name = "typos_lsp" }) == 0
          end,
        },
      }),
      linters_by_ft = require("languages").current().linters,
      extra_linters = { "codespell" },
    },
    config = function(ctx)
      require("lint_tools").setup(ctx.opts)
    end,
  },
}
