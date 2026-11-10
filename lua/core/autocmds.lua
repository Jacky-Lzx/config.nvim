local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup("ConfigCore", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    desc = "Disable automatic text wrapping and comment continuation",
    callback = function(event)
      vim.api.nvim_buf_call(event.buf, function()
        vim.opt_local.formatoptions:remove({ "t", "c", "a", "r", "o" })
      end)
    end,
  })

  vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "TermClose" }, {
    group = group,
    desc = "Reload externally changed files when the buffer is unmodified",
    callback = function(event)
      if not vim.api.nvim_buf_is_valid(event.buf) then
        return
      end
      local buffer = vim.bo[event.buf]
      if buffer.buftype == "" and not buffer.modified and vim.fn.getcmdwintype() == "" then
        vim.cmd.checktime({ args = { tostring(event.buf) } })
      end
    end,
  })

  vim.api.nvim_create_autocmd("TextYankPost", {
    group = group,
    desc = "Copy yanked text through the native clipboard provider",
    callback = function()
      require("core.clipboard").on_yank(vim.v.event)
    end,
  })
end

return M
