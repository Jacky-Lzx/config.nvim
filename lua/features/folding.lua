local M = {}
local windows = {}

local function source(buf)
  local ok, parser = pcall(vim.treesitter.get_parser, buf, nil, { error = false })
  if ok and parser then
    local found, query = pcall(vim.treesitter.query.get, parser:lang(), "folds")
    if found and query then
      return "expr", parser
    end
  end
  return "indent"
end

function M.attach(win)
  if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_config(win).relative ~= "" then
    return
  end
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "" or vim.bo[buf].filetype == "" or vim.wo[win].diff then
    return
  end
  local method, parser = source(buf)
  windows[win] = windows[win] or {}
  local state = windows[win][buf]
  if state and state.method == method then
    return
  end
  state = { method = method }
  windows[win][buf] = state
  vim.wo[win].foldmethod = method
  vim.wo[win].foldexpr = method == "expr" and "v:lua.vim.treesitter.foldexpr()" or "0"
  vim.wo[win].foldtext = "v:lua.require'features.folding'.text()"
  vim.wo[win].foldlevel = 99

  local function initialize()
    vim.schedule(function()
      if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= buf then
        -- Retry when this buffer is next displayed in the window.
        if windows[win] and windows[win][buf] == state then
          windows[win][buf] = nil
        end
        return
      end
      if windows[win][buf] ~= state then
        return
      end
      if vim.wo[win].diff then
        windows[win][buf] = nil
        return
      end
      if vim.wo[win].foldlevel ~= 99 then
        return
      end
      vim.api.nvim_win_call(win, function()
        -- FileType can invalidate the TS cache after our FileType callback.
        -- Recompute once after its handlers finish, before finding max depth.
        vim.cmd("normal! zX")
        -- zR sets the real maximum depth, so the first zm works immediately.
        vim.cmd("normal! zR")
      end)
    end)
  end
  if parser then
    vim.api.nvim_win_call(win, function()
      vim.treesitter.foldexpr(1)
    end)
    parser:parse(nil, function(err)
      if not err then
        initialize()
      end
    end)
  else
    initialize()
  end
end

-- Read public highlight queries once per folded line, rather than once per byte.
local function highlights(buf, row, limit)
  local result, priorities = {}, {}
  local ok, parser = pcall(vim.treesitter.get_parser, buf, nil, { error = false })
  if not ok or not parser or not vim.treesitter.highlighter.active[buf] then
    return result
  end
  parser:for_each_tree(function(tree, language)
    local query = vim.treesitter.query.get(language:lang(), "highlights")
    if not query then
      return
    end
    for id, node, metadata in query:iter_captures(tree:root(), buf, row, row + 1) do
      local range = vim.treesitter.get_range(node, buf, metadata[id])
      local first, col, last, end_col = range[1], range[2], range[4], range[5]
      if first <= row and last >= row then
        local from = first < row and 0 or col
        local to = last > row and limit or end_col
        local priority = tonumber(metadata.priority or (metadata[id] or {}).priority) or 100
        for byte = from, math.min(to, limit) - 1 do
          if priority >= (priorities[byte] or 0) then
            result[byte] = "@" .. query.captures[id] .. "." .. language:lang()
            priorities[byte] = priority
          end
        end
      end
    end
  end)
  return result
end

function M.text()
  local line = vim.fn.getline(vim.v.foldstart)
  local suffix = ("  󰁂 %d"):format(vim.v.foldend - vim.v.foldstart)
  local info = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
  local width = math.max(0, info.width - info.textoff)
  if vim.fn.strdisplaywidth(suffix) > width then
    suffix = tostring(vim.v.foldend - vim.v.foldstart)
    suffix = suffix:sub(1, width)
  end
  local available = math.max(0, width - vim.fn.strdisplaywidth(suffix))
  local chunks, used, byte = {}, 0, 0
  local colors = highlights(vim.api.nvim_get_current_buf(), vim.v.foldstart - 1, math.min(#line, available * 4))
  for char in line:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    local size = vim.fn.strdisplaywidth(char, used)
    if used + size > available then
      break
    end
    local color = colors[byte]
    if not color then
      local id = vim.fn.synID(vim.v.foldstart, byte + 1, true)
      color = id ~= 0 and vim.fn.synIDattr(id, "name") or "Folded"
    end
    local text = char == "\t" and string.rep(" ", size) or char
    local previous = chunks[#chunks]
    if previous and previous[2] == color then
      previous[1] = previous[1] .. text
    else
      chunks[#chunks + 1] = { text, color }
    end
    used, byte = used + size, byte + #char
  end
  chunks[#chunks + 1] = { suffix, "MoreMsg" }
  return chunks
end

function M.preview()
  local first = vim.fn.foldclosed(".")
  if first == -1 then
    return
  end
  local last = vim.fn.foldclosedend(".")
  -- Limit allocation for very large folds; the title makes truncation explicit.
  local stop = math.min(last, first + 199)
  local contents = vim.api.nvim_buf_get_lines(0, first - 1, stop, false)
  local title = (" Lines %d–%d%s "):format(first, last, stop < last and " (first 200 shown)" or "")
  local buf, win = vim.lsp.util.open_floating_preview(contents, vim.bo.filetype, {
    border = "rounded",
    title = title,
    focus_id = "fold_preview",
    wrap = false,
    max_width = math.max(1, math.min(100, vim.o.columns - 4)),
    max_height = math.max(1, math.min(20, vim.o.lines - 4)),
    close_events = { "CursorMoved", "CursorMovedI", "InsertEnter", "BufHidden" },
  })
  vim.keymap.set("n", "<Esc>", "<Cmd>close<CR>", { buffer = buf, silent = true, nowait = true })
  return buf, win
end

function M.setup()
  windows = {}
  vim.opt.foldenable = true
  vim.opt.foldcolumn = "0"
  vim.opt.foldlevel = 99
  vim.opt.foldlevelstart = 99
  vim.opt.fillchars:append({ fold = " ", foldopen = "▾", foldsep = "│", foldclose = "▸" })
  local group = vim.api.nvim_create_augroup("ConfigFolding", { clear = true })
  vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "WinEnter" }, {
    group = group,
    callback = function(event)
      if event.event == "FileType" then
        for _, win in ipairs(vim.fn.win_findbuf(event.buf)) do
          M.attach(win)
        end
      else
        M.attach(vim.api.nvim_get_current_win())
      end
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(event)
      windows[tonumber(event.match)] = nil
    end,
  })
  vim.api.nvim_create_autocmd("OptionSet", {
    group = group,
    pattern = "diff",
    callback = function()
      local win = vim.api.nvim_get_current_win()
      vim.schedule(function()
        M.attach(win)
      end)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(event)
      for _, buffers in pairs(windows) do
        buffers[event.buf] = nil
      end
    end,
  })
  M.attach(vim.api.nvim_get_current_win())
end

return M
