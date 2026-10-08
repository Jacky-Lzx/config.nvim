local count = 0
local sequence = 0
local child = vim.fn.jobstart({
  vim.v.progpath,
  "--headless",
  "--embed",
  "-i",
  "NONE",
  "--cmd",
  "lua dofile(vim.fn.stdpath('config') .. '/tests/setup.lua')",
}, { rpc = true, env = { NVIM_CONFIG_PROFILE = "default" } })
assert(child > 0, "Could not start the input test editor")

local function remote(code, ...)
  return vim.rpcrequest(child, "nvim_exec_lua", code, { ... })
end

local function wait_for(code, message)
  assert(
    vim.wait(2000, function()
      return remote(code)
    end, 10),
    message or code
  )
end

local function feed(keys)
  sequence = sequence + 1
  local sentinel = "<Cmd>lua vim.g.config_test_input_done=" .. sequence .. "<CR>"
  local bytes = keys .. sentinel
  assert(vim.rpcrequest(child, "nvim_input", bytes) == #bytes, "Input was truncated")
  wait_for("return vim.g.config_test_input_done == " .. sequence, "Input was not processed")
end

local function test(name, callback)
  callback()
  count = count + 1
  print("PASS: " .. name)
end

local function lines()
  return remote("return vim.api.nvim_buf_get_lines(0, 0, -1, false)")
end

local function expect(expected)
  assert(vim.deep_equal(lines(), expected), vim.inspect({ actual = lines(), expected = expected }))
end

local function reset(content)
  feed("<Esc>")
  remote(
    [[
    require("blink.cmp").hide()
    vim.cmd("enew!")
    vim.bo.filetype = "lua"
    vim.bo.indentexpr = ""
    vim.bo.autoindent = true
    vim.bo.smartindent = false
    vim.bo.cindent = false
    if ... then vim.api.nvim_buf_set_lines(0, 0, -1, false, ...) end
  ]],
    content
  )
end

local function input(keys, expected)
  reset()
  feed("i" .. keys .. "<Esc>")
  expect(expected)
end

local function complete_prefix()
  reset({ "alpha", "" })
  remote("vim.api.nvim_win_set_cursor(0, { 2, 0 })")
  feed("ialp")
  remote("require('blink.cmp').show({ providers = { 'buffer' } })")
  wait_for(
    "local cmp = require('blink.cmp'); return cmp.is_menu_visible() and #cmp.get_items() > 0",
    "The real buffer completion menu did not open"
  )
  assert(remote("return require('blink.cmp').get_selected_item() ~= nil"), "Completion was not preselected")
  assert(remote("return vim.api.nvim_get_current_line()") == "alp", "Completion inserted text without confirmation")
end

local function select_item(label)
  local size = remote("return #require('blink.cmp').get_items()")
  for _ = 1, size do
    if remote("local item = require('blink.cmp').get_selected_item(); return item and item.label == ...", label) then
      return
    end
    feed("<C-n>")
  end
  error("The completion item " .. label .. " was not selectable")
end

local function expand_trigger(trigger)
  reset()
  feed("i" .. trigger)
  remote("require('blink.cmp').show({ providers = { 'snippets' } })")
  wait_for("return require('blink.cmp').is_menu_visible() and #require('blink.cmp').get_items() > 0")
  select_item(trigger)
  feed("<Tab>")
  wait_for("return require('luasnip').session.current_nodes[vim.api.nvim_get_current_buf()] ~= nil")
end

local function run()
  wait_for("return vim.fn.exists(':ConfigInfo') == 2", "The test editor did not start")
  test("input plugins stay unloaded until an editing event", function()
    assert(remote("return require('config.plugins').status().started"))
    assert(remote("return not package.loaded['blink.cmp'] and not package.loaded.luasnip and not package.loaded.pairs"))
  end)
  feed("i<Esc>")
  wait_for("return package.loaded['blink.cmp.completion'] ~= nil", "Completion setup did not finish")
  assert(
    remote("return require('blink.cmp.fuzzy').implementation_type == 'rust'"),
    "The installed Rust matcher was not used"
  )
  local pairing = remote("return require('features.input.pairing').source().available")
  assert(remote("return package.loaded.pairs ~= nil") == pairing)

  test("plain Enter and Tab preserve editing fallback", function()
    input("first<CR><Tab>second", { "first", "  second" })
  end)
  test("pairing and empty-pair backspace follow local availability", function()
    input("(", { pairing and "()" or "(" })
    input("(<BS>", { "" })
  end)
  test("rapid empty-pair newline observes preceding input", function()
    input("(<CR>x", pairing and { "(", "  x", ")" } or { "(", "x" })
  end)
  test("quotes retain conservative apostrophe behavior", function()
    input("don't", { "don't" })
    input("中文'", { "中文'" })
    input('"hello"', { '"hello"' })
  end)
  if pairing then
    test("pairing toggle leaves ordinary input available", function()
      remote("require('pairs').disable()")
      input("(", { "(" })
      remote("require('pairs').enable()")
      input("(", { "()" })
    end)
    test("pair newline retains native undo and redo", function()
      input("(<CR>x", { "(", "  x", ")" })
      feed("u")
      expect({ "" })
      feed("<C-r>")
      expect({ "(", "  x", ")" })
    end)
  end
  test("Enter confirms the preselected completion without navigation", function()
    complete_prefix()
    feed("<CR>")
    wait_for("return vim.api.nvim_get_current_line() == 'alpha'")
    expect({ "alpha", "alpha" })
  end)
  test("Enter confirms an explicitly selected real completion", function()
    complete_prefix()
    select_item("alpha")
    feed("<CR>")
    wait_for("return vim.api.nvim_get_current_line() == 'alpha'")
    expect({ "alpha", "alpha" })
  end)
  test("Tab confirms a selected completion", function()
    complete_prefix()
    select_item("alpha")
    feed("<Tab>")
    wait_for("return vim.api.nvim_get_current_line() == 'alpha'")
    expect({ "alpha", "alpha" })
  end)

  test("Alt-j/k and Alt-d/u navigate without inserting previews", function()
    reset({ "alpha1 alpha2 alpha3 alpha4 alpha5 alpha6 alpha7 alpha8 alpha9", "" })
    remote("vim.api.nvim_win_set_cursor(0, { 2, 0 })")
    feed("ialpha")
    remote("require('blink.cmp').show({ providers = { 'buffer' } })")
    wait_for("return require('blink.cmp').is_menu_visible() and #require('blink.cmp').get_items() >= 9")
    for _, action in ipairs({ { "<A-j>", 2 }, { "<A-d>", 7 }, { "<A-u>", 2 }, { "<Down>", 3 }, { "<A-k>", 2 } }) do
      feed(action[1])
      wait_for("return require('blink.cmp.completion.list').selected_item_idx == " .. action[2])
      assert(remote("return vim.api.nvim_get_current_line()") == "alpha")
    end
  end)
  test("Alt-/ toggles completion and Ctrl-e dismisses it", function()
    complete_prefix()
    feed("<A-/>")
    wait_for("return not require('blink.cmp').is_menu_visible()")
    feed("<A-/>")
    wait_for("return require('blink.cmp').is_menu_visible()")
    feed("<C-e>")
    wait_for("return not require('blink.cmp').is_menu_visible()")
    expect({ "alpha", "alp" })
  end)
  test("Alt-n/p cycle sources within the current buffer", function()
    complete_prefix()
    local defaults = remote("return table.concat(require('blink.cmp.config').sources.default, ',')")
    for _, action in ipairs({
      { "<A-n>", "buffer" },
      { "<A-n>", "snippets" },
      { "<A-n>", "lsp,path" },
      { "<A-n>", defaults },
      { "<A-p>", "lsp,path" },
    }) do
      feed(action[1])
      wait_for(
        ("local ctx = require('blink.cmp.completion.trigger').context; return ctx and table.concat(ctx.providers, ',') == %q"):format(
          action[2]
        )
      )
    end
    reset()
    feed("i<A-p>")
    wait_for("return vim.b.blink_cmp_provider_index == 4")
  end)
  test("Shift-Enter inserts a newline without accepting completion", function()
    complete_prefix()
    select_item("alpha")
    feed("<S-CR>")
    expect({ "alpha", "alp", "" })
  end)

  remote([[
    local ls = require("luasnip")
    ls.add_snippets("lua", {
      ls.parser.parse_snippet({ trig = "zz" }, "${1:first} + ${2:second}$0"),
      ls.parser.parse_snippet({ trig = "qq" }, "$1 + ${2:second}$0"),
    })
  ]])
  test("Tab accepts snippet completion and snippet fields remain editable", function()
    expand_trigger("zz")
    expect({ "first + second" })
    feed("one")
    remote("require('blink.cmp').hide()")
    remote("require('luasnip').jump(1)")
    wait_for("return vim.api.nvim_win_get_cursor(0)[2] >= 5")
    feed("two")
    expect({ "one + two" })
    remote("require('blink.cmp').hide()")
    feed("<S-Tab>")
    wait_for("return vim.api.nvim_win_get_cursor(0)[2] < 4")
    feed("ONE")
    expect({ "ONE + two" })
  end)
  test("manual snippet expansion preserves preceding text across undo", function()
    reset()
    feed("ihead")
    remote([[
      local ls = require('luasnip')
      ls.snip_expand(ls.parser.parse_snippet('', '<${1:field}>$0'))
    ]])
    feed("<Esc>u")
    expect({ "head" })
    feed("<C-r>")
    expect({ "head<field>" })
  end)
  test("automatic snippets expand while typing", function()
    remote([[
      local ls = require('luasnip')
      ls.add_snippets('lua', { ls.snippet({ trig = 'aa', snippetType = 'autosnippet' }, { ls.text_node('automatic') }) })
    ]])
    input("aa", { "automatic" })
  end)
  test("jsregexp transforms update on leaving Insert mode", function()
    reset()
    feed("i")
    remote([[
      local ls = require('luasnip')
      assert(require('luasnip.util.jsregexp'), 'The native jsregexp component is missing')
      ls.snip_expand(ls.parser.parse_snippet('', '${1:word} -> ${1/(.*)/${1:/upcase}/}$0'))
    ]])
    feed("text<Esc>")
    expect({ "text -> TEXT" })
  end)
  test("Tab inserts normally inside a snippet when no completion is selected", function()
    expand_trigger("zz")
    feed("one")
    remote("require('blink.cmp').hide()")
    feed("<Tab>")
    expect({ "one  + second" })
    remote("require('luasnip').jump(1)")
    wait_for("return vim.api.nvim_win_get_cursor(0)[2] >= 7")
    feed("two")
    expect({ "one  + two" })
  end)
  test("Alt-j/k and Alt-c control snippet choices when the menu is closed", function()
    reset()
    feed("i")
    remote([[
      local ls = require('luasnip')
      ls.snip_expand(ls.snippet('', { ls.choice_node(1, { ls.text_node('red'), ls.text_node('blue') }), ls.text_node(' + '), ls.insert_node(2, 'tail'), ls.insert_node(0) }))
      require('blink.cmp').hide()
    ]])
    wait_for("return not require('blink.cmp').is_menu_visible()")
    feed("<A-j>")
    wait_for("return vim.api.nvim_get_current_line() == 'blue + tail'")
    feed("<A-k>")
    wait_for("return vim.api.nvim_get_current_line() == 'red + tail'")
    remote([[
      _G.config_test_select = vim.ui.select
      vim.ui.select = function(items, options, callback)
        assert(options.kind == 'luasnip' and #items == 2)
        callback(items[2], 2)
        vim.g.config_test_choice_selected = true
      end
    ]])
    feed("<A-c>")
    wait_for("return vim.g.config_test_choice_selected and vim.api.nvim_get_current_line() == 'blue + tail'")
    remote("vim.ui.select = _G.config_test_select")
  end)
  if pairing then
    test("pair newline cooperates with snippet placeholder tracking", function()
      expand_trigger("qq")
      feed("(<CR>x")
      expect({ "(", "  x", ") + second" })
      remote("require('blink.cmp').hide()")
      remote("require('luasnip').jump(1)")
      wait_for("return vim.api.nvim_win_get_cursor(0)[1] == 3")
      feed("done")
      expect({ "(", "  x", ") + done" })
    end)
  end
  test("snippet navigation does not leak into another buffer", function()
    input("<S-Tab>plain", { "  plain" })
  end)
  test("command-line Enter executes typed text and Tab confirms completion", function()
    reset()
    feed("<Esc>")
    remote([[
      for _, name in ipairs({ 'ConfigTest', 'ConfigTestFirst', 'ConfigTestSecond' }) do
        vim.api.nvim_create_user_command(name, function() vim.g.config_test_command = name end, {})
      end
    ]])
    vim.rpcrequest(child, "nvim_input", ":ConfigTest")
    wait_for(
      "return vim.fn.getcmdtype() == ':' and require('blink.cmp').is_menu_visible() and #require('blink.cmp').get_items() >= 3"
    )
    vim.rpcrequest(child, "nvim_input", "<C-n>")
    wait_for("local item = require('blink.cmp').get_selected_item(); return item and item.label ~= 'ConfigTest'")
    assert(remote("return vim.fn.getcmdline()") == "ConfigTest")
    vim.rpcrequest(child, "nvim_input", "<CR>")
    wait_for("return vim.g.config_test_command == 'ConfigTest' and vim.fn.getcmdtype() == ''")
    vim.rpcrequest(child, "nvim_input", ":ConfigTestFi")
    wait_for("return vim.fn.getcmdtype() == ':' and require('blink.cmp').is_menu_visible()")
    vim.rpcrequest(child, "nvim_input", "<Tab>")
    wait_for("return vim.fn.getcmdline() == 'ConfigTestFirst'")
    vim.rpcrequest(child, "nvim_input", "<CR>")
    wait_for("return vim.g.config_test_command == 'ConfigTestFirst' and vim.fn.getcmdtype() == ''")
  end)
  test("native Visual write works after completion is loaded", function()
    reset()
    local path = vim.fs.joinpath(vim.env.NVIM_TEST_TMP, "input-write.txt")
    remote(
      [[
      local path = ...
      vim.fn.writefile({ "first", "second", "third" }, path)
      vim.cmd.edit(vim.fn.fnameescape(path))
      vim.api.nvim_buf_set_lines(0, 2, 3, false, { "edited third" })
    ]],
      path
    )
    feed("ggVj:w<CR>")
    assert(vim.deep_equal(vim.fn.readfile(path), { "first", "second", "edited third" }))
  end)
  test("the native file browser remains available with the plugin manager", function()
    local directory = vim.fs.joinpath(vim.env.NVIM_TEST_TMP, "work")
    vim.fn.writefile({ "fixture" }, directory .. "/input-fixture.txt")
    remote("vim.cmd.Explore(vim.fn.fnameescape(...))", directory)
    local listing = table.concat(lines(), "\n")
    assert(listing:find("input-fixture.txt", 1, true), listing)
  end)
  local errors = remote("return _G.config_test_errors")
  assert(#errors == 0, table.concat(errors, "\n"))
  io.stdout:write(
    ("\nInput checks: %d passed (%s)\n"):format(count, pairing and "local pairing" or "pairing unavailable")
  )
  io.stdout:flush()
end

local ok, err = xpcall(run, debug.traceback)
pcall(vim.rpcnotify, child, "nvim_command", "qa!")
if vim.fn.jobwait({ child }, 1000)[1] == -1 then
  vim.fn.jobstop(child)
end
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd.cquit(1)
end
vim.cmd.qa({ bang = true })
