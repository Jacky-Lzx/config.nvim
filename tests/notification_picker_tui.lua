-- Exercise the configured picker through the real <leader>sN mapping and UI input.
local tools = require("notification-tools")
local result = assert(vim.env.NVIM_LAZY_RESULT)
local origin, source, picker, failed
local function finish(ok, message)
  vim.fn.writefile(vim.split(message, "\n", { plain = true }), result)
  vim.cmd(ok and "qa!" or "cquit 1")
end
local function later(ms, callback)
  vim.defer_fn(function()
    if failed then
      return
    end
    local ok, err = xpcall(callback, debug.traceback)
    if not ok then
      failed = true
      finish(false, err)
    end
  end, ms)
end
local function contents(buf)
  return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
end
local function buffer(filetype)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    -- selection-tools assigns the content filetype after filling its preview.
    if ft == filetype or filetype == "selection_tools_preview" and (ft == "markdown" or ft == "text") then
      return buf, win
    end
  end
  error("Missing UI: " .. filetype)
end
local function input(keys)
  vim.api.nvim_input(vim.keycode(keys))
end
local function screen()
  vim.cmd.redraw()
  local rows = {}
  for row = 1, vim.o.lines do
    local cells = {}
    for col = 1, vim.o.columns do
      cells[#cells + 1] = vim.fn.screenstring(row, col)
    end
    rows[row] = table.concat(cells)
  end
  return table.concat(rows, "\n")
end
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    later(100, function()
      assert(#vim.api.nvim_list_uis() > 0)
      local plugins = require("lazy.core.config").plugins
      assert(not plugins["noice.nvim"] and not package.loaded.noice)
      assert(vim.fn.filereadable(vim.env.NVIM_CONFIG_ROOT .. "/lua/plugins/ui/noice.lua") == 0)
      local locks = vim.json.decode(table.concat(vim.fn.readfile(vim.env.NVIM_CONFIG_ROOT .. "/lazy-lock.json"), "\n"))
      assert(not locks["noice.nvim"])
      tools.dismiss()
      tools.clear_tasks()
      tools.clear_history()
      origin = vim.api.nvim_get_current_win()
      source = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_win_set_buf(origin, source)
      vim.api.nvim_buf_set_lines(source, 0, -1, false, { "keep original source" })
      tools.notify("body-only ZXQ-482\n中文🙂\n" .. string.rep("long message\n", 30) .. "last full line", "warn", {
        title = "Compiler warning",
        source = "compiler",
        details = "untruncated detail",
        timeout = 0,
      })
      tools.notify("unrelated message", "error", { title = "Server notice", source = "lua_ls", timeout = 0 })
      tools.notify("latest message", "info", { title = "Latest", details = "detail-only UQ-517", timeout = 0 })
      input(" sN")
    end)
    later(350, function()
      local buf = buffer("selection_tools_input")
      assert(vim.api.nvim_get_current_buf() == buf)
      assert(contents(buffer("selection_tools_preview")):find("detail-only UQ-517", 1, true))
      assert(screen():find("Latest", 1, true))
      input("zxq482") -- Fuzzy match across a hyphen in the body, beyond the title.
    end)
    later(600, function()
      local list = contents(buffer("selection_tools_list"))
      assert(list:find("Compiler warning", 1, true) and not list:find("Server notice", 1, true), list)
      local preview = contents(buffer("selection_tools_preview"))
      assert(preview:find("中文🙂", 1, true) and preview:find("last full line", 1, true), preview)
      assert(preview:find("untruncated detail", 1, true))
      assert(screen():find("Compiler warning", 1, true))
      input("<C-d>")
    end)
    later(800, function()
      local _, win = buffer("selection_tools_preview")
      local view = vim.api.nvim_win_call(win, vim.fn.winsaveview)
      assert(view.topline > 1, "Preview scrolling did not move through the full message")
      input("<C-w>zzzzunmatched")
    end)
    later(1050, function()
      assert(contents(buffer("selection_tools_list")):find("No results", 1, true))
      input("<C-w>uq517")
    end)
    later(1300, function()
      local list = contents(buffer("selection_tools_list"))
      assert(list:find("Latest", 1, true) and not list:find("Compiler warning", 1, true), list)
      input("<C-w>lua_ls")
    end)
    later(1550, function()
      local list = contents(buffer("selection_tools_list"))
      assert(list:find("Server notice", 1, true) and not list:find("Latest", 1, true), list)
      input("<C-w>zxq482")
    end)
    later(1750, function()
      assert(contents(buffer("selection_tools_list")):find("Compiler warning", 1, true))
      input("<CR>")
    end)
    later(1850, function()
      assert(vim.b.notification_tools_detail == true)
      local body = contents(vim.api.nvim_get_current_buf())
      assert(body:find("last full line", 1, true) and body:find("untruncated detail", 1, true))
      input("q")
    end)
    later(2050, function()
      assert(vim.api.nvim_get_current_win() == origin)
      assert(contents(source) == "keep original source" and vim.bo[source].modified)
      input(" sN")
    end)
    later(2300, function()
      buffer("selection_tools_input")
      input("<Esc>")
    end)
    later(2500, function()
      assert(vim.api.nvim_get_current_win() == origin and vim.api.nvim_get_mode().mode == "n")
      assert(contents(source) == "keep original source")
      assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
      picker = tools.pick_history({ source = "compiler" })
    end)
    later(2750, function()
      assert(#picker.matches == 1)
      tools.teardown()
      assert(picker.closed and not vim.api.nvim_buf_is_valid(picker.preview_buf))
      assert(vim.api.nvim_get_current_win() == origin)
      finish(
        true,
        "Terminal checks passed: no Noice, configured history mapping, fuzzy body/details/source search, full Unicode preview, scrolling, zero matches, reading, cancellation and teardown"
      )
    end)
  end,
})
