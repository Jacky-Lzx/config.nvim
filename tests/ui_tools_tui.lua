-- Run through tests/tui.py: real startup, UIEnter/VeryLazy and actual key dispatch.
local function feed(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), "xt", false)
end

local function check()
  assert(vim.g.did_very_lazy)
  local plugins = require("lazy.core.config").plugins
  assert(plugins["ui-tools.nvim"]._.loaded)
  assert(not plugins["nvim-scrollbar"] and not package.loaded.scrollbar)
  assert(not package.loaded["features.column_guide"])
  local snacks = require("lazy.core.plugin").values(plugins["snacks.nvim"], "opts", false)
  assert(not snacks.indent.enabled and not snacks.statuscolumn.enabled)
  assert(not snacks.zen.enabled and not snacks.dim.enabled)
  for _, name in ipairs({ "indent", "statuscolumn", "zen", "dim" }) do
    assert(not package.loaded["snacks." .. name], "Competing Snacks UI loaded: " .. name)
  end
  local ui = require("ui_tools")
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
  assert(info.textoff == 8, "Expected two-cell sign and fold slots: " .. info.textoff)
  local rows = assert(column.cache[win], "Source window with inherited column was not adopted")
  local diagnostic = assert(rows[3] and rows[3].diagnostic, "Native diagnostic sign missing")
  assert(diagnostic.sign_hl_group == "DiagnosticSignError", "Error must take precedence")
  local icon = diagnostic.sign_text:gsub("%s+$", "")
  assert(vim.fn.screenstring(info.winrow + info.winbar + 2, info.wincol) == icon, "Diagnostic icon not drawn")
  local diagnostics = require("features.lsp.diagnostics")
  diagnostics.set_enabled(false)
  assert(not ((column.cache[win] or {})[3] or {}).diagnostic, "Disabled diagnostic remained cached")
  diagnostics.set_enabled(true)
  assert(column.cache[win][3].diagnostic, "Diagnostic toggle did not restore the sign")
  vim.diagnostic.reset(diagnostic_ns, 0)
  column.refresh()
  assert(
    vim.fn.screenstring(info.winrow + info.winbar, info.wincol + info.textoff + 120) == "",
    "Configured column guide not visible"
  )

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
  assert(plugins["nvim-hlslens"]._.loaded, "Search lens must remain functional")
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
  pattern = "VeryLazy",
  once = true,
  callback = function()
    vim.defer_fn(function()
      local ok, err = xpcall(check, debug.traceback)
      local result = ok
          and "ui-tools configured TUI: ownership, compact diagnostics, guide, pulse/yank, keys, Zen/Zoom typing/restore, search and scrollbar passed"
        or err
      vim.fn.writefile(vim.split(result, "\n", { plain = true }), vim.env.NVIM_LAZY_RESULT)
      vim.cmd(ok and "quitall!" or "cquit 1")
    end, 120)
  end,
})
