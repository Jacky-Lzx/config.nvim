local M = {}

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("lzx_treesitter", { clear = true }),
    callback = function(ev)
      -- TeX keeps its language-specific highlighting/conceal policy.
      if ev.match ~= "tex" then
        pcall(vim.treesitter.start, ev.buf)
      end
    end,
  })
end

return M
