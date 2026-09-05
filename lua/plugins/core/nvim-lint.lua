return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufWritePost" },
    dependencies = {
      {
        "mason-org/mason.nvim",
        optional = true,
        opts_extend = { "ensure_installed" },
        opts = {
          ensure_installed = { "codespell", "typos" },
        },
      },
    },
    opts = {
      linters = {},
      linters_by_ft = {},
    },
    config = function(_, opts)
      -- Configure linters
      local lint = require("lint")
      lint.linters_by_ft = opts.linters_by_ft
      for name, config in pairs(opts.linters) do
        lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name] or {}, config)
      end

      -- require("snacks.debug").inspect(require("lint").linters_by_ft)

      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        group = vim.api.nvim_create_augroup("lzx_lint", { clear = true }),
        callback = function()
          -- try_lint without arguments runs the linters defined in `linters_by_ft`
          -- for the current filetype
          lint.try_lint()

          -- You can call `try_lint` with a linter name or a list of names to always
          -- run specific linters, independent of the `linters_by_ft` configuration
          lint.try_lint("codespell")
          -- require("lint").try_lint("typos")
        end,
      })
    end,
  },
}
