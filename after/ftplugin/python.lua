local makeprg = [["$NVIM_PYTHON_MAKE" %:p:S]]
vim.opt_local.makeprg = makeprg

vim.api.nvim_create_autocmd("QuickFixCmdPre", {
  group = vim.api.nvim_create_augroup("PythonMake", { clear = true }),
  pattern = { "make", "lmake" },
  callback = function()
    if vim.bo.filetype == "python" and vim.bo.makeprg == makeprg then
      -- makeprg is already expanded here; the shell reads this variable later.
      vim.env.NVIM_PYTHON_MAKE = require("utils.platform").python()
    end
  end,
})
