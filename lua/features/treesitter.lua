local M = {}

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("lzx_treesitter", { clear = true }),
    callback = function(ev)
      if not vim.b[ev.buf].config_treesitter_disabled then
        pcall(vim.treesitter.start, ev.buf)
      end
    end,
  })
end

return M
