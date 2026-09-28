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
          ensure_installed = { "codespell" },
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
        callback = function(ev)
          if
            not vim.api.nvim_buf_is_loaded(ev.buf)
            or vim.bo[ev.buf].buftype ~= ""
            or vim.bo[ev.buf].filetype == ""
            or vim.api.nvim_buf_get_offset(ev.buf, vim.api.nvim_buf_line_count(ev.buf)) > 1024 * 1024
          then
            return
          end
          vim.api.nvim_buf_call(ev.buf, function()
            lint.try_lint()
            if
              vim.fn.executable("codespell") == 1
              and #vim.lsp.get_clients({ bufnr = ev.buf, name = "typos_lsp" }) == 0
            then
              lint.try_lint("codespell")
            end
          end)
        end,
      })
    end,
  },
}
