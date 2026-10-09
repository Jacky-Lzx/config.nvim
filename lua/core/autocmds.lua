local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup("ConfigCore", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    desc = "Disable automatic comment wrapping and continuation",
    callback = function(event)
      vim.api.nvim_buf_call(event.buf, function()
        vim.opt_local.formatoptions:remove({ "c", "r", "o" })
      end)
    end,
  })

  vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "TermClose" }, {
    group = group,
    desc = "Reload externally changed files when the buffer is unmodified",
    callback = function(event)
      local buffer = vim.bo[event.buf]
      if buffer.buftype == "" and not buffer.modified and vim.fn.getcmdwintype() == "" then
        vim.cmd.checktime({ args = { tostring(event.buf) } })
      end
    end,
  })

  vim.api.nvim_create_autocmd("TextYankPost", {
    group = group,
    desc = "Highlight yanked text briefly",
    callback = function()
      vim.hl.on_yank({ higroup = "IncSearch", timeout = 250 })
    end,
  })
end

return M
