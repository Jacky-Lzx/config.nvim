local M = {}
local namespace = vim.api.nvim_create_namespace("bibtex-preview-spacing")

-- Called only by the owning renderer, with its current document and window.
function M.render(ctx)
  local buf, win = ctx.buf, ctx.win
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
  if ctx.preview then
    return
  end
  local raw = ctx.item and ctx.item.documentation or ctx.contents
  if type(raw) == "table" and raw.kind then
    if raw.kind ~= "markdown" then
      return
    end
    raw = raw.value
  end
  if ctx.syntax and ctx.syntax ~= "markdown" then
    return
  end
  raw = type(raw) == "table" and table.concat(raw, "\n") or raw
  if type(raw) ~= "string" or not raw:match("^%s*```+bibtex%s*\n.-\n```+%s*$") then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local first, last, hidden = 1, #lines, {}
  local function trim()
    while first <= last and lines[first]:match("^%s*$") do
      hidden[#hidden + 1], first = first - 1, first + 1
    end
    while last >= first and lines[last]:match("^%s*$") do
      hidden[#hidden + 1], last = last - 1, last - 1
    end
  end
  trim()
  -- Native hover keeps fences; completion has already removed them.
  if first < last and lines[first]:match("^%s*```+bibtex%s*$") and lines[last]:match("^%s*```+%s*$") then
    hidden[#hidden + 1], hidden[#hidden + 2] = first - 1, last - 1
    first, last = first + 1, last - 1
    trim()
  end
  for _, row in ipairs(hidden) do
    vim.api.nvim_buf_set_extmark(buf, namespace, row, 0, { conceal_lines = "" })
  end
  vim.wo[win].conceallevel = 2
  local height = math.max(1, vim.api.nvim_win_text_height(win, {}).all)
  vim.api.nvim_win_set_height(win, math.min(vim.api.nvim_win_get_height(win), height))
end

return M
