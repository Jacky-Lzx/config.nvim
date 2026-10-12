local M = {}

local excluded = {
  lspinfo = true,
  packer = true,
  checkhealth = true,
  help = true,
  man = true,
}

function M.setup(opts)
  opts = vim.tbl_extend("force", { column = 121, char = "" }, opts or {})
  assert(
    type(opts.column) == "number" and opts.column >= 1 and opts.column % 1 == 0,
    "Guide column must be a positive integer"
  )
  assert(
    type(opts.char) == "string" and vim.fn.strdisplaywidth(opts.char) == 1,
    "Guide character must occupy one display cell"
  )
  local ns = vim.api.nvim_create_namespace("ConfigColumnGuide")
  local columns = {}

  vim.api.nvim_set_decoration_provider(ns, {
    on_start = function()
      columns = {}
    end,
    on_win = function(_, win, buf)
      if
        vim.bo[buf].buftype ~= ""
        or excluded[vim.bo[buf].filetype]
        or vim.api.nvim_win_get_config(win).relative ~= ""
      then
        return false
      end
      local view = vim.api.nvim_win_call(win, vim.fn.winsaveview)
      local info = vim.fn.getwininfo(win)[1]
      local column = opts.column - 1 - view.leftcol
      if column < 0 or column >= info.width - info.textoff then
        return false
      end
      columns[win] = column
    end,
    on_range = function(_, win, buf, first, _, last, end_col)
      local column = columns[win]
      if not column then
        return
      end
      local stop = math.min(last + (end_col > 0 and 1 or 0), vim.api.nvim_buf_line_count(buf))
      vim.api.nvim_win_call(win, function()
        local row = first
        while row < stop do
          local folded = vim.fn.foldclosed(row + 1)
          local width = folded == row + 1 and vim.fn.strdisplaywidth(vim.fn.foldtextresult(row + 1))
            or vim.fn.virtcol({ row + 1, "$" }) - 1
          if (folded == -1 or folded == row + 1) and width < opts.column then
            vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
              virt_text = { { opts.char, "NonText" } },
              virt_text_win_col = column,
              virt_text_pos = "overlay",
              hl_mode = "combine",
              priority = 1,
              ephemeral = true,
            })
          end
          row = folded ~= -1 and vim.fn.foldclosedend(row + 1) or row + 1
        end
      end)
    end,
  })
end

return M
