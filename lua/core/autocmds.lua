local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup("ConfigCore", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    desc = "Keep typing from wrapping text or continuing comments",
    callback = function(event)
      local formatoptions = vim.bo[event.buf].formatoptions
      vim.bo[event.buf].formatoptions = formatoptions:gsub("[tcro]", "")
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
