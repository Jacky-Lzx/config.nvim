return {
  -- formatters
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    keys = {
      {
        "<leader>gf",
        function()
          require("conform").format({ lsp_format = "fallback" })
        end,
        desc = "Format",
      },
    },
    opts = {
      formatters_by_ft = vim.tbl_extend(
        "force",
        { ["_"] = { "trim_whitespace" } },
        require("languages").current().formatters
      ),
      formatters = require("languages").current().formatter_options,
      format_on_save = function(bufnr)
        -- Disable with a global or buffer-local variable
        if
          vim.g.enable_autoformat
          and not vim.b[bufnr].disable_autoformat
          and vim.b[bufnr].enable_autoformat ~= false
        then
          return { timeout_ms = 500, lsp_format = "fallback" }
        end
      end,
    },
    config = function(_, opts)
      require("conform").setup(opts)

      if vim.g.enable_autoformat == nil then
        vim.g.enable_autoformat = true
      end
      require("snacks").toggle
        .new({
          id = "auto_format",
          name = "Auto format",
          get = function()
            return vim.g.enable_autoformat
          end,
          set = function(state)
            vim.g.enable_autoformat = state
          end,
        })
        :map("<leader>tf")
    end,
  },
}
