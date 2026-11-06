return {
  -- formatters
  {
    main = "conform",
    id = "conform.nvim",
    -- enabled = false,
    source = "stevearc/conform.nvim",
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
    config = function(ctx)
      do
        if vim.g.enable_autoformat == nil then
          vim.g.enable_autoformat = true
        end
        -- Allow opting out before the first save, without loading the formatter.
        vim.keymap.set("n", "<leader>tf", function()
          vim.g.enable_autoformat = not vim.g.enable_autoformat
        end, { desc = "Toggle auto format" })
        require("keymap_tools").register("formatting", {
          toggles = {
            {
              keys = "<leader>tf",
              name = "Auto format",
              get = function()
                return vim.g.enable_autoformat
              end,
            },
          },
        })
      end
      require("config.bindings").set("conform.nvim", {
        {
          "<leader>gf",
          function()
            require("conform").format({ lsp_format = "fallback" })
          end,
          desc = "Format",
        },
      })
      local opts = ctx.opts
      require("conform").setup(opts)
    end,
  },
}
