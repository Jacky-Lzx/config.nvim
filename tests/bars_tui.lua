local function pause(ms)
  coroutine.yield(ms)
end
local last_keys
local function feed(keys)
  last_keys = keys
  vim.api.nvim_feedkeys(vim.keycode(keys), "xt", false)
end
local function check()
  local plugins = require("config.plugins").nodes()
  for _, name in ipairs({ "barbar.nvim", "lualine.nvim", "copilot-lualine" }) do
    assert(not plugins[name], name)
  end
  local buffers, status = require("ui_tools.bufferline"), require("ui_tools.statusline")
  assert(buffers.enabled and status.enabled)
  local function winbar()
    return vim.api.nvim_eval_statusline(vim.wo.winbar, { winid = 0, use_winbar = true, maxwidth = 160 }).str
  end
  local function check_winbar(name)
    assert(vim.wo.winbar:find("ui_tools.winbar", 1, true), "Missing winbar for " .. name)
    assert(winbar():find(name, 1, true), "Missing winbar filename: " .. winbar())
  end
  local paths, bufs = {}, {}
  for _, name in ipairs({ "first.txt", "中文%second.txt", "last.txt" }) do
    local path = vim.env.NVIM_TEST_TMP .. "/" .. name
    vim.fn.writefile({ name }, path)
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    paths[#paths + 1], bufs[#bufs + 1] = path, vim.api.nvim_get_current_buf()
    check_winbar(name)
    pause(100)
    check_winbar(name)
  end
  pause(100)
  local function at(buf)
    assert(vim.api.nvim_get_current_buf() == buf, "Wrong buffer after " .. tostring(last_keys))
    check_winbar(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t"))
  end
  feed("[b")
  at(bufs[2])
  feed("]b")
  at(bufs[3])
  feed("<A-h>")
  at(bufs[2])
  feed("<A-l>")
  at(bufs[3])
  local items = buffers.items()
  local position = vim.fn.index(
    vim.tbl_map(function(item)
      return item.buf
    end, items),
    bufs[2]
  ) + 1
  feed("<A-" .. position .. ">")
  at(bufs[2])
  feed("<A-S-,>")
  assert(buffers.items()[position - 1].buf == bufs[2])
  feed("<A-S-.>")
  assert(buffers.items()[position].buf == bufs[2])
  feed("<A-<>")
  assert(buffers.items()[position - 1].buf == bufs[2])
  feed("<A->>")
  assert(buffers.items()[position].buf == bufs[2])
  feed("<A-w>")
  assert(not vim.api.nvim_buf_is_valid(bufs[2]))
  feed("<A-u>")
  assert(
    vim.api.nvim_buf_get_name(0) == vim.uv.fs_realpath(paths[2]),
    "restore: " .. vim.api.nvim_buf_get_name(0) .. " expected " .. tostring(vim.uv.fs_realpath(paths[2]))
  )
  assert(vim.api.nvim_get_current_line() == "中文%second.txt")
  pause(100)
  check_winbar("中文%second.txt")
  -- Continuous edits/cursor motion must not rescan diagnostics or clients.
  local count, clients = vim.diagnostic.count, vim.lsp.get_clients
  local queries, traces = 0, {}
  local function query()
    -- Native default statuslines in other windows may run luaeval() during
    -- redrawstatus. Check the direct owner, not that redraw's ancestor stack.
    local owner = debug.getinfo(3, "S").source
    if
      owner:find("/ui_tools/statusline.lua", 1, true)
      or owner:find("/ui_tools/winbar.lua", 1, true)
      or owner:find("/features/bars.lua", 1, true)
    then
      queries = queries + 1
      traces[#traces + 1] = debug.traceback()
    end
  end
  vim.diagnostic.count = function(...)
    query()
    return count(...)
  end
  vim.lsp.get_clients = function(...)
    query()
    return clients(...)
  end
  feed("i" .. string.rep("abcdefghij", 50) .. "<Esc>")
  pause(100)
  feed("0llllhh")
  status.update()
  pause(100)
  assert(queries == 0, "Bars queried providers during editing: " .. table.concat(traces, "\n"))
  vim.diagnostic.count, vim.lsp.get_clients = count, clients
  local function rendered()
    return vim.api.nvim_eval_statusline(vim.wo.statusline, { winid = 0, maxwidth = 160 }).str
  end
  assert(rendered():find("[+]", 1, true), rendered())
  local diagnostics = vim.api.nvim_create_namespace("ConfiguredBarDiagnostics")
  local items = {}
  for i = 1, 2 do
    items[#items + 1] = { lnum = 0, col = 0, severity = 2, message = "warning" .. i }
  end
  for i = 1, 3 do
    items[#items + 1] = { lnum = 0, col = 0, severity = 4, message = "hint" .. i }
  end
  vim.diagnostic.set(diagnostics, 0, items)
  pause(100)
  assert(rendered():find("2 󰌵3", 1, true), rendered())
  vim.diagnostic.reset(diagnostics, 0)
  pause(100)
  feed("qa")
  assert(
    rendered():find("REC @a", 1, true),
    "macro reg=" .. vim.fn.reg_recording() .. " mode=" .. vim.fn.mode() .. " bar=" .. rendered()
  )
  feed("q")
  assert(not rendered():find("REC @a", 1, true))
  local source = vim.api.nvim_get_current_win()
  vim.cmd("FileTools open")
  pause(150)
  assert(buffers.render():find(string.rep(" ", 41), 1, true), "Missing tree offset")
  local tree_win, tree_buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  local source_buf = vim.api.nvim_win_get_buf(source)
  local cycle, cycle_calls = buffers.cycle, 0
  buffers.cycle = function(...)
    cycle_calls = cycle_calls + 1
    return cycle(...)
  end
  feed("<A-h><A-l>[b]b<A-1><A-w><A-u>")
  pause(100)
  assert(cycle_calls == 0, "Files inherited global buffer navigation")
  assert(vim.api.nvim_get_current_win() == tree_win and vim.api.nvim_get_current_buf() == tree_buf)
  assert(vim.wo[tree_win].winfixbuf and vim.api.nvim_win_get_buf(source) == source_buf)
  buffers.cycle = cycle
  vim.cmd("FileTools close")
  vim.api.nvim_set_current_win(source)
  feed("<A-h>")
  assert(vim.api.nvim_get_current_buf() ~= source_buf, "Editor buffer navigation was disabled")
  feed("<A-l>")
  assert(vim.api.nvim_get_current_buf() == source_buf)
  vim.cmd("vsplit")
  pause(100)
  assert(vim.wo.statusline:find("ui_tools.statusline", 1, true))
  assert(vim.wo.winbar:find("ui_tools.winbar", 1, true))
  local split = vim.api.nvim_get_current_win()
  vim.cmd("edit " .. vim.fn.fnameescape(paths[1]))
  pause(100)
  local function visible_winbar(win)
    local pos = vim.api.nvim_win_get_position(win)
    local chars = {}
    for col = pos[2] + 1, pos[2] + vim.api.nvim_win_get_width(win) do
      chars[#chars + 1] = vim.fn.screenstring(pos[1] + 1, col)
    end
    return table.concat(chars)
  end
  vim.cmd("redraw!")
  assert(visible_winbar(source):find("%second.txt", 1, true), visible_winbar(source))
  assert(visible_winbar(split):find("first.txt", 1, true), visible_winbar(split))
  feed("<C-w>p")
  pause(100)
  vim.cmd("redraw!")
  assert(visible_winbar(source):find("%second.txt", 1, true), visible_winbar(source))
  assert(visible_winbar(split):find("first.txt", 1, true), visible_winbar(split))
  feed(" Z")
  feed(" Z")
  assert(not require("ui_tools.focus").state())
  assert(next(status.errors) == nil, vim.inspect(status.errors))
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
end
vim.api.nvim_create_autocmd("User", {
  pattern = "ConfigReady",
  once = true,
  callback = function()
    local worker = coroutine.create(check)
    local function advance()
      local ok, delay = coroutine.resume(worker)
      if not ok or coroutine.status(worker) == "dead" then
        local message = ok and "bars TUI: exact mappings, restore, symbols, burst edits, macro, tree and splits passed"
          or debug.traceback(worker, tostring(delay))
        vim.fn.writefile(vim.split(message, "\n", { plain = true }), vim.env.NVIM_STARTUP_RESULT)
        vim.cmd(ok and "qa!" or "cquit")
      else
        -- Return to Neovim's real input loop so BufModifiedSet/TextChanged and
        -- the coalesced bar refresh run between editing bursts and assertions.
        vim.defer_fn(advance, delay)
      end
    end
    vim.defer_fn(advance, 100)
  end,
})
