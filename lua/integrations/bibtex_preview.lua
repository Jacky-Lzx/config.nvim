local M = {}
local namespace = vim.api.nvim_create_namespace("bibtex-preview-spacing")

function M.compact(bufnr, resize)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local fence = lines[1] and lines[1]:match("^(```+)bibtex%s*$")
  if not fence or lines[#lines] ~= fence then
    return
  end
  local hidden = { 0, #lines - 1 }
  local first, last = 2, #lines - 1
  while first <= last and lines[first]:match("^%s*$") do
    hidden[#hidden + 1] = first - 1
    first = first + 1
  end
  while last >= first and lines[last]:match("^%s*$") do
    hidden[#hidden + 1] = last - 1
    last = last - 1
  end
  for _, row in ipairs(hidden) do
    vim.api.nvim_buf_set_extmark(bufnr, namespace, row, 0, { conceal_lines = "" })
  end
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      vim.wo[win].conceallevel = 2
      if resize then
        local height = math.max(1, vim.api.nvim_win_text_height(win, {}).all)
        vim.api.nvim_win_set_height(win, math.min(vim.api.nvim_win_get_height(win), height))
      end
    end
  end
end

function M.draw(opts)
  opts.default_implementation()
  M.compact(opts.window:get_buf(), false)
end

function M.setup()
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup("BibtexPreviewSpacing", { clear = true }),
    callback = function(event)
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(event.buf) then
          return
        end
        for _, win in ipairs(vim.fn.win_findbuf(event.buf)) do
          if vim.api.nvim_win_get_config(win).relative ~= "" then
            M.compact(event.buf, true)
            return
          end
        end
      end)
    end,
  })
end

return M
