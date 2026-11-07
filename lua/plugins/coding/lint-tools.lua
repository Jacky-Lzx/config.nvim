return {
  {
    id = "lint-tools.nvim",
    main = "lint_tools",
    enabled = true,
    source = "Jacky-Lzx/lint-tools.nvim",
    version = "main",
    dev = true,
    after = { "toolchain-tools.nvim" },
    dependencies = { "toolchain-tools.nvim" },
    opts = {
      linters = vim.tbl_deep_extend("force", require("languages").current().linter_options, {
        codespell = {
          condition = function(ctx)
            return not vim.b[ctx.bufnr].bigfile
              and not require("features.files").detect(ctx.bufnr)
              and #vim.lsp.get_clients({ bufnr = ctx.bufnr, name = "typos_lsp" }) == 0
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
