assert(vim.fn.executable("rg") == 1, "Search checks require ripgrep")
local editor = dofile(vim.fn.stdpath("config") .. "/tests/editor.lua")
local remote, wait, feed = editor.remote, editor.wait, editor.feed
editor.run(function()
  local project = vim.env.NVIM_TEST_TMP .. "/search project"
  vim.fn.mkdir(project .. "/nested", "p")
  assert(vim.system({ "git", "init", "-q", project }):wait().code == 0)
  local alpha, target = project .. "/alpha.txt", project .. "/nested/target ü.txt"
  vim.fn.writefile({ "alpha content", "shared marker" }, alpha)
  vim.fn.writefile({ "first line", "specific_search_value", "last line" }, target)
  vim.fn.writefile({ "ignored.txt" }, project .. "/.gitignore")
  vim.fn.writefile({ "specific_search_value" }, project .. "/ignored.txt")
  remote("vim.cmd.cd(...)", project)

  local function ready(source)
    wait(
      "local p = require('snacks').picker.get()[1]; return p and p.opts.source == '"
        .. source
        .. "' and vim.fn.mode() == 'i'"
    )
  end

  local function filter(pattern)
    feed(pattern)
    wait("local p = require('snacks').picker.get()[1]; return p and p.list:count() == 1 and not p:is_active()")
  end

  local function confirm(path, line)
    feed("<CR>")
    wait("return #require('snacks').picker.get() == 0")
    assert(remote("return vim.api.nvim_buf_get_name(0)") == path)
    if line then
      assert(remote("return vim.api.nvim_win_get_cursor(0)[1]") == line)
    end
  end

  feed(" sf")
  ready("files")
  wait("local p = require('snacks').picker.get()[1]; return p and p.list:count() >= 2 and not p:is_active()")
  assert(remote([[
    for item in require("snacks").picker.get()[1]:iter() do
      if item.file:find("ignored.txt", 1, true) then return false end
    end
    return true
  ]]))
  if vim.env.NVIM_TEST_PICKER_TOOLS == "rg-only" then
    assert(remote("return require('snacks.picker.source.files').get_cmd() == 'rg'"))
  end
  filter("'target")
  wait(
    "local p = require('snacks').picker.get()[1]; return p and vim.api.nvim_buf_get_lines(p.preview.win.buf, 0, 1, false)[1] == 'first line'"
  )
  confirm(target)

  feed(" sg")
  ready("grep")
  filter("specific_search_value")
  assert(remote("return require('snacks').picker.get()[1]:current().pos[1] == 2"))
  confirm(target, 2)
  feed(" sr")
  ready("grep")
  wait("local p = require('snacks').picker.get()[1]; return p and p.list:count() == 1 and not p:is_active()")
  assert(remote("return require('snacks').picker.get()[1].opts.search == 'specific_search_value'"))
  confirm(target, 2)

  remote("local alpha, target = ...; vim.cmd.edit(alpha); vim.cmd.edit(target)", alpha, target)
  feed(" sb")
  ready("buffers")
  filter("'alpha")
  confirm(alpha)
  feed(" ,")
  ready("buffers")
  filter("'target")
  confirm(target)
  remote("vim.cmd.edit(...)", alpha)
  feed(" sR")
  ready("recent")
  filter("'target")
  confirm(target)

  remote(
    [[
    local alpha, target = ...
    local ns = vim.api.nvim_create_namespace("config_search_checks")
    vim.diagnostic.set(ns, vim.fn.bufnr(alpha), { { lnum = 0, col = 0, message = "alpha diagnostic", severity = vim.diagnostic.severity.WARN } })
    vim.diagnostic.set(ns, vim.fn.bufnr(target), { { lnum = 1, col = 0, message = "target diagnostic", severity = vim.diagnostic.severity.ERROR } })
  ]],
    alpha,
    target
  )
  feed(" sD")
  ready("diagnostics_buffer")
  wait("local p = require('snacks').picker.get()[1]; return p and p.list:count() == 1 and not p:is_active()")
  confirm(target, 2)
  feed(" sd")
  ready("diagnostics")
  wait("local p = require('snacks').picker.get()[1]; return p and p.list:count() == 2 and not p:is_active()")
  filter("'alpha")
  confirm(alpha, 1)
end, "Search checks: files, preview, grep, resume, buffers, recent files and diagnostic jumps passed")
