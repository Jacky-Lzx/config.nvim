assert(vim.fn.executable("lua-language-server") == 1, "Live checks require lua-language-server")
local editor = dofile(vim.fn.stdpath("config") .. "/tests/editor.lua")
local remote, wait, feed = editor.remote, editor.wait, editor.feed
editor.run(
  function()
    local project = vim.env.NVIM_TEST_TMP .. "/picker-project"
    vim.fn.mkdir(project, "p")
    vim.fn.writefile({ "{}" }, project .. "/.luarc.json")
    local path = project .. "/sample.lua"
    vim.fn.writefile({
      "local function target()",
      "  return 42",
      "end",
      "local function caller()",
      "  return target()",
      "end",
      "print(target())",
      "print(caller())",
      "print(target())",
    }, path)
    remote("vim.cmd.edit(...); vim.api.nvim_win_set_cursor(0, { 7, 7 })", path)
    wait(
      "local client = vim.lsp.get_clients({ bufnr = 0, name = 'lua_ls' })[1]; return client and client.initialized",
      20000
    )
    feed("gd")
    wait("return vim.api.nvim_win_get_cursor(0)[1] == 1 and #require('snacks').picker.get() == 0", 20000)
    remote("vim.api.nvim_win_set_cursor(0, { 1, 17 })")
    feed("gi")
    wait(
      "local p = require('snacks').picker.get()[1]; return p and p.list:count() >= 3 and vim.fn.mode() == 'i'",
      20000
    )
    remote(
      [[
    local picker = require("snacks").picker.get()[1]
    local found = false
    for item in picker:iter() do if item.file == ... and item.pos[1] == 7 then found = true end end
    assert(found, "Real references did not contain the fixture's call")
  ]],
      path
    )
    feed("<CR>")
    wait("return #require('snacks').picker.get() == 0 and vim.api.nvim_win_get_cursor(0)[1] > 1")
    feed(" ss")
    wait(
      "local p = require('snacks').picker.get()[1]; return p and p.list:count() >= 2 and vim.fn.mode() == 'i'",
      20000
    )
    feed("caller")
    wait(
      "local p = require('snacks').picker.get()[1]; return p and p.list:count() == 1 and p:current().text:find('caller', 1, true) ~= nil"
    )
    feed("<CR>")
    wait("return #require('snacks').picker.get() == 0 and vim.api.nvim_win_get_cursor(0)[1] == 4")
    remote("vim.api.nvim_win_set_cursor(0, { 1, 17 })")
    assert(
      not remote("return vim.lsp.get_clients({ bufnr = 0 })[1]:supports_method('textDocument/prepareCallHierarchy')")
    )
    feed("gci")
    wait(
      "return #require('snacks').picker.get() == 0 and vim.api.nvim_exec2('messages', {output = true}).output:find('No results found for `lsp_incoming_calls`', 1, true) ~= nil"
    )
    assert(remote("return vim.api.nvim_win_get_cursor(0)[1] == 1"))
    feed("gco")
    wait(
      "return #require('snacks').picker.get() == 0 and vim.api.nvim_exec2('messages', {output = true}).output:find('No results found for `lsp_outgoing_calls`', 1, true) ~= nil"
    )
    feed("<Esc> sS")
    wait(
      "local p = require('snacks').picker.get()[1]; return p and p.list:count() >= 2 and vim.fn.mode() == 'i'",
      20000
    )
    remote("for _, p in ipairs(require('snacks').picker.get()) do p:close() end")
  end,
  "Picker live checks: real definition, references, document/workspace symbols and unsupported-method handling passed"
)
