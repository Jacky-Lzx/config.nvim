-- Run through tests/tui.py: real startup, UIEnter/ConfigReady and actual key dispatch.
local function feed(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), "xt", false)
end

local function check()
  assert(vim.g.config_ready)
  local plugins = require("config.plugins").nodes()
  assert(require("config.plugins").initialized("ui-tools.nvim"))
  assert(not plugins["nvim-scrollbar"] and not package.loaded.scrollbar)
  assert(not package.loaded["features.column_guide"])
  assert(not plugins["snacks.nvim"], "Snacks must no longer own editor features")
  for _, name in ipairs({ "indent", "statuscolumn", "zen", "dim", "scope" }) do
    assert(not package.loaded["snacks." .. name], "Competing Snacks UI loaded: " .. name)
  end
  local ui = require("ui_tools")
  assert(not package.loaded["ui_tools.animate"] and not package.loaded["ui_tools.scroll"])
  feed(" ta")
  assert(require("ui_tools.animate").enabled)
  feed(" tS")
  assert(require("ui_tools.scroll").enabled)
  feed(" tS")
  feed(" ta")
  assert(not require("ui_tools.scroll").enabled and not require("ui_tools.animate").enabled)
  feed(" tPp")
  local profiler = require("debug_tools.profiler")
  assert(profiler.running)
  feed(" tPp")
  assert(not profiler.running and vim.bo.filetype == "debug-tools-profile")
  feed("q")
  feed(" tPh")
  assert(profiler.highlighted)
  feed(" tPh")
  assert(not profiler.highlighted)
  local render = require("ui_tools.render")
  assert(render.sources.indent and render.sources.guide)
  local file = vim.env.NVIM_TEST_TMP .. "/ui-tools.txt"
  vim.cmd.edit(file)
  local lines = { "function main()", "  if ready then", "    body()", "", "    done()", "  end", "end" }
  for i = 8, 200 do
    lines[i] = "line " .. i
  end
  lines[151] = "body target"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { 3, 4 })
  vim.wo.foldlevel = 99
  local column = require("ui_tools.statuscolumn")
  column.refresh()
  assert(vim.wo.statuscolumn:find("ui_tools", 1, true))
  local diagnostic_ns = vim.api.nvim_create_namespace("UiToolsConfiguredDiagnostics")
  vim.diagnostic.set(diagnostic_ns, 0, {
    { lnum = 2, col = 0, severity = vim.diagnostic.severity.WARN, message = "warning" },
    { lnum = 2, col = 0, severity = vim.diagnostic.severity.ERROR, message = "error" },
  })
  vim.wait(80)
  column.refresh()
  vim.cmd("redraw!")
  local win = vim.api.nvim_get_current_win()
  local info = vim.fn.getwininfo(win)[1]
  assert(info.textoff == 9, "Expected separate symbol columns and one padding cell: " .. info.textoff)
  assert(
    vim.fn.screenstring(vim.fn.screenpos(win, 1, 1).row, info.wincol + info.textoff - 1) == " ",
    "Gutter padding missing"
  )
  local rows = assert(column.cache[win], "Source window with inherited column was not adopted")
  local diagnostic = assert(rows[3] and rows[3].diagnostic, "Native diagnostic sign missing")
  assert(diagnostic.sign_hl_group == "DiagnosticSignError", "Error must take precedence")
  local icon = diagnostic.sign_text:gsub("%s+$", "")
  assert(vim.fn.screenstring(vim.fn.screenpos(win, 3, 1).row, info.wincol) == icon, "Diagnostic icon not drawn")
  vim.api.nvim_buf_set_mark(0, "a", 3, 0, {})
  column.refresh()
  vim.cmd("redraw!")
  local diagnostic_row = vim.fn.screenpos(win, 3, 1).row
  assert(vim.fn.screenstring(diagnostic_row, info.wincol) == icon, "Mark hid the diagnostic")
  assert(vim.fn.screenstring(diagnostic_row, info.wincol + 1) == "a", "Mark missing from second symbol column")
  local sign_ns = vim.api.nvim_create_namespace("UiToolsConfiguredOtherSign")
  vim.api.nvim_buf_set_extmark(0, sign_ns, 2, 0, { sign_text = "B", sign_hl_group = "Special", priority = 1 })
  column.refresh()
  vim.cmd("redraw!")
  assert(vim.fn.screenstring(diagnostic_row, info.wincol) == icon, "Other sign hid the diagnostic")
  assert(vim.fn.screenstring(diagnostic_row, info.wincol + 1) == "B", "Other sign missing from second column")
  vim.api.nvim_buf_clear_namespace(0, sign_ns, 0, -1)
  vim.api.nvim_buf_del_mark(0, "a")
  column.refresh()
  local diagnostics = require("features.lsp.diagnostics")
  diagnostics.set_enabled(false)
  assert(not ((column.cache[win] or {})[3] or {}).diagnostic, "Disabled diagnostic remained cached")
  diagnostics.set_enabled(true)
  assert(column.cache[win][3].diagnostic, "Diagnostic toggle did not restore the sign")
  vim.diagnostic.reset(diagnostic_ns, 0)
  column.refresh()
  assert(
    vim.fn.screenstring(vim.fn.screenpos(win, 1, 1).row, info.wincol + info.textoff + 120) == "",
    "Configured column guide not visible"
  )

  -- Match git-tools' actual signs=false / numhl=true output.
  local git_ns = vim.api.nvim_create_namespace("GitToolsConfiguredNumberTest")
  vim.api.nvim_buf_set_extmark(0, git_ns, 2, 0, { number_hl_group = "GitToolsChange", priority = 6 })
  column.refresh()
  local git_row = assert(column.cache[win][3].git_numbers, "Git numhl-only mark was not adopted")
  local color = assert(vim.api.nvim_get_hl(0, { name = "GitToolsChange", link = false }).fg, "Git color missing")
  assert(vim.api.nvim_get_hl(0, { name = git_row[1], link = false }).fg == color, "Git number lost its color")
  assert(vim.api.nvim_get_hl(0, { name = git_row[2], link = false }).bold, "Current Git number lost emphasis")
  for _, kind in ipairs({ "Add", "Change", "Delete" }) do
    local hl = vim.api.nvim_get_hl(0, { name = "GitTools" .. kind, link = false })
    assert(hl.fg and not hl.bg, "Git number must have a foreground and no background: " .. kind)
  end
  assert(column.options.layout[4] == "fold", "Git should not share the fold slot")
  vim.api.nvim_buf_clear_namespace(0, git_ns, 0, -1)
  column.refresh()
  assert(not column.cache[win][3] or not column.cache[win][3].git_numbers, "Cleared Git color remained")

  -- Exercise deeper fold columns through the actual configured renderer/theme.
  local folding = { method = vim.wo.foldmethod, level = vim.wo.foldlevel, view = vim.fn.winsaveview() }
  vim.wo.foldmethod = "manual"
  vim.cmd("normal! zE")
  for _, range in ipairs({ { 2, 30 }, { 4, 25 }, { 6, 20 }, { 8, 15 } }) do
    vim.cmd(range[1] .. "," .. range[2] .. "fold")
    vim.cmd("normal! zR")
  end
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.cmd("normal! zt")
  column.refresh()
  vim.cmd("redraw!")
  local fold_info = vim.fn.getwininfo(win)[1]
  assert(fold_info.textoff == 9, "Configured fold area and padding grew with nesting")
  for level = 1, 4 do
    local row = vim.fn.screenpos(win, level * 2, 1).row
    local col = math.min(level, 2)
    assert(vim.fn.screenstring(row, fold_info.wincol + 5 + col) == "▾", "Missing fold level " .. level)
    if level > 1 then
      assert(vim.fn.screenstring(row, fold_info.wincol + 6) == "│", "Inner fold displaced the first layer")
    end
  end
  vim.cmd("normal! zE")
  vim.wo.foldmethod, vim.wo.foldlevel = folding.method, folding.level
  vim.fn.winrestview(folding.view)
  column.refresh()
  vim.cmd("redraw!")

  feed("  ")
  local ns = assert(vim.api.nvim_get_namespaces().UiToolsFeedback)
  assert(#vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {}) > 0, "Pulse key did not flash the line")
  local yank = vim.hl.on_yank
  local highlighted = 0
  vim.hl.on_yank = function(opts)
    highlighted = highlighted + 1
    assert(opts.higroup == "IncSearch" and opts.timeout == 200)
    return yank(opts)
  end
  feed("yy")
  vim.hl.on_yank = yank
  assert(highlighted == 1, "Yank feedback must run exactly once")
  feed(" tG")
  assert(not render.sources.indent)
  feed(" tG")
  assert(render.sources.indent)
  feed(" tD")
  assert(require("ui_tools.focus").dimmed)
  feed(" tD")
  assert(not require("ui_tools.focus").dimmed)

  vim.cmd("vsplit")
  local source = vim.api.nvim_get_current_win()
  local layout = vim.fn.winlayout()
  local old_number, old_statuscolumn = vim.wo.number, vim.wo.statuscolumn
  feed(" Z")
  assert(require("ui_tools.focus").state().mode == "zen")
  assert(not vim.wo.number)
  feed("A -- continued typing<Esc>")
  assert(vim.api.nvim_get_current_line():find("continued typing", 1, true))
  feed(" Z")
  assert(not require("ui_tools.focus").state())
  assert(vim.api.nvim_get_current_win() == source)
  assert(vim.deep_equal(layout, vim.fn.winlayout()))
  assert(vim.wo.number == old_number and vim.wo.statuscolumn == old_statuscolumn)
  feed(" z")
  assert(require("ui_tools.focus").state().mode == "zoom")
  feed(" z")
  assert(vim.deep_equal(layout, vim.fn.winlayout()))
  feed(" Z")
  feed("qq")
  assert(vim.wait(500, function()
    return not require("ui_tools.focus").state()
  end))
  assert(vim.deep_equal(layout, vim.fn.winlayout()))

  feed("/body<CR>")
  assert(require("config.plugins").initialized("motion-tools.nvim"), "Search lens must remain functional")
  local scrollbar = require("ui_tools.scrollbar")
  scrollbar.refresh()
  assert(vim.tbl_count(scrollbar.bars) == 2)
  assert(scrollbar.providers.git_tools)
  assert(not package.loaded["scrollbar.handlers.search"])
  local bar = scrollbar.bars[vim.api.nvim_get_current_win()]
  local cursor_row = scrollbar.project(
    vim.api.nvim_win_get_cursor(0)[1],
    vim.api.nvim_buf_line_count(0),
    vim.api.nvim_buf_line_count(bar.buf)
  )
  assert(
    vim.api.nvim_buf_get_lines(bar.buf, cursor_row - 1, cursor_row, false)[1] == "●",
    "Configured cursor indicator missing"
  )
  assert(vim.tbl_contains(vim.api.nvim_buf_get_lines(bar.buf, 0, -1, false), "•"), "Search markers missing")
  feed("//")
  scrollbar.refresh()
  assert(
    not vim.tbl_contains(vim.api.nvim_buf_get_lines(bar.buf, 0, -1, false), "•"),
    "Search markers survived nohlsearch"
  )
  assert(next(scrollbar.errors) == nil, vim.inspect(scrollbar.errors))
  assert(next(render.errors) == nil, vim.inspect(render.errors))
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
end

vim.api.nvim_create_autocmd("User", {
  pattern = "ConfigReady",
  once = true,
  callback = function()
    vim.defer_fn(function()
      local ok, err = xpcall(check, debug.traceback)
      local result = ok
          and "ui-tools configured TUI: ownership, compact diagnostics, guide, pulse/yank, keys, Zen/Zoom typing/restore, search and scrollbar passed"
        or err
      vim.fn.writefile(vim.split(result, "\n", { plain = true }), vim.env.NVIM_STARTUP_RESULT)
      vim.cmd(ok and "quitall!" or "cquit 1")
    end, 120)
  end,
})
