assert(vim.fn.executable("lua-language-server") == 1, "Live checks require lua-language-server on PATH")
local count, sequence = 0, 0
local child = vim.fn.jobstart({
  vim.v.progpath,
  "--headless",
  "--embed",
  "-i",
  "NONE",
  "--cmd",
  "lua dofile(vim.fn.stdpath('config') .. '/tests/setup.lua')",
}, { rpc = true })
assert(child > 0)
local function remote(code, ...)
  return vim.rpcrequest(child, "nvim_exec_lua", code, { ... })
end
local function wait_for(code, timeout)
  assert(
    vim.wait(timeout or 10000, function()
      return remote(code) == true
    end, 20),
    code
  )
end
local function feed(keys)
  sequence = sequence + 1
  vim.rpcrequest(child, "nvim_input", keys .. "<Cmd>lua vim.g.config_lsp_input=" .. sequence .. "<CR>")
  wait_for("return vim.g.config_lsp_input == " .. sequence)
end
local function test(name, callback)
  callback()
  count = count + 1
  print("PASS: " .. name)
end
local function run()
  wait_for("return vim.fn.exists(':ConfigLspInfo') == 2")
  local project = vim.env.NVIM_TEST_TMP .. "/lua-project"
  vim.fn.mkdir(project, "p")
  vim.fn.writefile({
    '{"diagnostics.globals":[],"workspace.checkThirdParty":false,"format.defaultConfig":{"indent_style":"space","indent_size":"2"}}',
  }, project .. "/.luarc.json")
  local path = project .. "/sample.lua"
  vim.fn.writefile({
    "local number = 1",
    "print(number)",
    "print(missing_symbol)",
    "local sample = { value = 42 }",
    "print(sample.value)",
  }, path)
  remote("vim.cmd.edit(vim.fn.fnameescape(...))", path)
  wait_for(
    "local client = vim.lsp.get_clients({ bufnr = 0, name = 'lua_ls' })[1]; return client and client.initialized",
    20000
  )
  test("a real Lua server attaches at the project root with completion capabilities", function()
    assert(
      remote(
        "local client = vim.lsp.get_clients({ bufnr = 0, name = 'lua_ls' })[1]; return client.config.root_dir == ...",
        project
      )
    )
    assert(
      remote(
        "local client = vim.lsp.get_clients({ bufnr = 0, name = 'lua_ls' })[1]; return client.config.capabilities.textDocument.completion.completionItem.snippetSupport"
      )
    )
    assert(remote("return vim.fn.maparg(' rn', 'n', false, true).buffer == 1"))
    wait_for("return require('blink.cmp.fuzzy').implementation_type == 'rust'")
  end)
  test("real diagnostics arrive and existing toggle keys control their display", function()
    wait_for(
      "for _, diagnostic in ipairs(vim.diagnostic.get(0)) do if diagnostic.code == 'undefined-global' and diagnostic.message:find('missing_symbol', 1, true) then return true end end return false",
      20000
    )
    feed(" tv")
    assert(remote("local cfg = vim.diagnostic.config().virtual_text; return cfg.spacing == 0 and cfg.format({}) == ''"))
    feed(" tv")
    assert(remote("return vim.diagnostic.config().virtual_text.spacing == 4"))
    feed(" tV")
    assert(remote("return vim.diagnostic.config().virtual_lines.current_line"))
    feed(" tV")
    assert(remote("return vim.diagnostic.config().virtual_lines == false"))
    feed(" td")
    assert(remote("return not vim.diagnostic.is_enabled()"))
    feed(" td")
    assert(remote("return vim.diagnostic.is_enabled()"))
  end)
  test("hover and definition return actual server results", function()
    remote([[
      local client = vim.lsp.get_clients({ bufnr = 0, name = 'lua_ls' })[1]
      local position = { textDocument = { uri = vim.uri_from_bufnr(0) }, position = { line = 1, character = 7 } }
      local hover = assert(client:request_sync('textDocument/hover', position, 10000, 0))
      assert(not hover.err and hover.result and hover.result.contents)
      local definition = assert(client:request_sync('textDocument/definition', position, 10000, 0))
      assert(not definition.err and definition.result)
      local locations = definition.result
      local location = locations.uri and locations or locations[1]
      assert(location and (location.range or location.targetSelectionRange).start.line == 0)
    ]])
  end)
  test("rename edits the declaration and reference through the server", function()
    remote("vim.api.nvim_win_set_cursor(0, { 1, 7 }); vim.lsp.buf.rename('total')")
    wait_for(
      "local lines = vim.api.nvim_buf_get_lines(0, 0, 2, false); return lines[1] == 'local total = 1' and lines[2] == 'print(total)'"
    )
  end)
  test("formatting uses the attached language server", function()
    remote([[
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'local sample={value=42}', 'print(sample.value)' })
      vim.lsp.buf.format({ async = false, timeout_ms = 10000 })
    ]])
    assert(remote("return vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]:find('local sample =', 1, true) ~= nil"))
  end)
  test("Blink receives a real LSP field completion and Tab confirms it", function()
    remote(
      "vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'local sample = { value = 42 }', '' }); vim.api.nvim_win_set_cursor(0, { 2, 0 })"
    )
    feed("isample.va")
    remote("require('blink.cmp').show({ providers = { 'lsp' } })")
    wait_for(
      "for _, item in ipairs(require('blink.cmp').get_items()) do if item.label == 'value' and item.source_id == 'lsp' then return true end end return false"
    )
    local items = remote("return #require('blink.cmp').get_items()")
    for _ = 1, items do
      if remote("local item = require('blink.cmp').get_selected_item(); return item and item.label == 'value'") then
        break
      end
      feed("<C-n>")
    end
    assert(remote("local item = require('blink.cmp').get_selected_item(); return item and item.label == 'value'"))
    feed("<Tab>")
    wait_for("return vim.api.nvim_get_current_line() == 'sample.value'")
    feed("<Esc>")
  end)
  test("another file in the same project reuses the client and mappings stay buffer-local", function()
    local id = remote("return vim.lsp.get_clients({ bufnr = 0, name = 'lua_ls' })[1].id")
    local second = project .. "/second.lua"
    vim.fn.writefile({ "return 2" }, second)
    remote("vim.cmd.edit(vim.fn.fnameescape(...))", second)
    wait_for("return #vim.lsp.get_clients({ bufnr = 0, name = 'lua_ls' }) == 1")
    assert(remote("return vim.lsp.get_clients({ bufnr = 0, name = 'lua_ls' })[1].id") == id)
    remote("vim.cmd.enew(); vim.bo.filetype = 'text'")
    assert(
      remote(
        "return #vim.lsp.get_clients({ bufnr = 0 }) == 0 and vim.tbl_isempty(vim.fn.maparg(' rn', 'n', false, true))"
      )
    )
  end)
  local errors = remote("return _G.config_test_errors")
  assert(#errors == 0, table.concat(errors, "\n"))
  io.stdout:write(("\nLSP live checks: %d passed\n"):format(count))
  io.stdout:flush()
end
local ok, err = xpcall(run, debug.traceback)
pcall(
  remote,
  [[
  local clients = vim.lsp.get_clients()
  for _, client in ipairs(clients) do client:stop() end
  vim.wait(5000, function()
    for _, client in ipairs(clients) do if not client:is_stopped() then return false end end
    return true
  end, 20)
]]
)
pcall(vim.rpcnotify, child, "nvim_command", "qa!")
if vim.fn.jobwait({ child }, 2000)[1] == -1 then
  vim.fn.jobstop(child)
end
if not ok then
  print(err)
  vim.cmd.cquit()
end
vim.cmd.qa({ bang = true })
