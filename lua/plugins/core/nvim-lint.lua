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
    config = function(_, opts)
      require("lint").linters_by_ft["fish"] = { "fish" }
      require("lint").linters_by_ft["bash"] = { "bash" }

      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function()
          -- try_lint without arguments runs the linters defined in `linters_by_ft`
          -- for the current filetype
          require("lint").try_lint()

          -- You can call `try_lint` with a linter name or a list of names to always
          -- run specific linters, independent of the `linters_by_ft` configuration
          require("lint").try_lint("codespell")
          require("lint").try_lint("typos")
        end,
      })
    end,
  },
}
