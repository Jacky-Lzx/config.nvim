return {
  -- formatters
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    keys = {},
    opts = {
      format_on_save = function(_)
        -- Disable with a global or buffer-local variable
        if vim.g.enable_autoformat then
          return { timeout_ms = 500, lsp_format = "fallback" }
        end
      end,
    },
    init = function()
      vim.g.enable_autoformat = true
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
    config = function(_, opts)
      opts["formatters_by_ft"].javascript = { "prettierd", "prettier", stop_after_first = true }
      opts["formatters_by_ft"]["_"] = { "trim_whitespace" }

      require("conform").setup(opts)
    end,
  },
}
