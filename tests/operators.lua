local editor = dofile(vim.fn.stdpath("config") .. "/tests/editor.lua")
local remote, feed = editor.remote, editor.feed
local mode = assert(vim.env.NVIM_TEST_OPERATORS_MODE)
editor.run(function()
  local status = remote("return require('config.plugins').status().features.operators")
  local function reset(lines, cursor)
    feed("<Esc>")
    remote(
      [[
      local lines, cursor = ...
      vim.cmd.enew({bang=true})
      vim.bo.filetype = 'lua'
      vim.api.nvim_buf_set_lines(0,0,-1,false,lines)
      vim.api.nvim_win_set_cursor(0, cursor or {1,0})
    ]],
      lines,
      cursor
    )
  end
  local function expect(lines)
    local actual = remote("return vim.api.nvim_buf_get_lines(0,0,-1,false)")
    assert(vim.deep_equal(actual, lines), vim.inspect({ expected = lines, actual = actual }))
  end
  if mode == "missing" or mode == "disabled" or mode == "core" then
    assert(not status.active and remote("return package.loaded['mini.operators'] == nil"))
    for _, key in ipairs({ "cr", "crr", "gm", "gmm", "gs", "gss", "g=", "g==", "gxx" }) do
      assert(remote("return vim.fn.maparg(..., 'n') == ''", key))
    end
    assert(remote("return vim.fn.maparg('gx','n',false,true).desc:find('URI under cursor',1,true) ~= nil"))
    reset({ "word" })
    feed("ciwX<Esc>")
    expect({ "X" })
    feed("u")
    expect({ "word" })
    return
  end
  assert(status.active and status.available)
  assert(remote("return package.loaded['mini.operators'] ~= nil"))
  assert(remote("return MiniOperators.config.replace.prefix == 'cr'"))
  assert(remote("return vim.fn.maparg('grn','n',false,true).desc:find('vim.lsp',1,true) ~= nil"))
  assert(remote("return vim.fn.maparg('gX','n',false,true).desc:find('URI under cursor',1,true) ~= nil"))
  reset({ "first", "second" })
  remote("vim.fn.setreg('a','value','v'); vim.fn.setreg('x','saved','v')")
  feed('"acriw')
  expect({ "value", "second" })
  feed("j.")
  expect({ "value", "value" })
  feed("u")
  expect({ "value", "second" })
  assert(remote("return vim.fn.getreg('a') == 'value' and vim.fn.getreg('x') == 'saved'"))
  reset({ "word" })
  feed('viw"acr')
  expect({ "value" })
  reset({ "word" })
  remote("vim.fn.setreg('a','X','v')")
  feed('"a2criw')
  expect({ "XX" })
  reset({ "    old()", "next()" })
  remote("vim.fn.setreg('a', ...)", "  new()\n", "V")
  feed('"acrr')
  expect({ "    new()", "next()" })

  reset({ "word", "next" })
  local register = remote("return vim.fn.getreginfo('a')")
  feed("2gmiw")
  expect({ "wordwordword", "next" })
  feed("u")
  expect({ "word", "next" })
  feed("gmm")
  expect({ "word", "word", "next" })
  feed("j.")
  expect({ "word", "word", "next", "next" })
  assert(vim.deep_equal(remote("return vim.fn.getreginfo('a')"), register))
  assert(remote("return vim.fn.getreg('x') == 'saved'"))
  reset({ "word" }, { 1, 2 })
  feed("v2hgm")
  expect({ "worword" })

  reset({ "c, a, b" })
  feed("gss")
  expect({ "a, b, c" })
  feed("u")
  expect({ "c, a, b" })
  reset({ "z", "b", "a" })
  feed("V2jgs")
  expect({ "a", "b", "z" })
  reset({ "1 + 2" })
  feed("g==")
  expect({ "3" })
  feed("u")
  expect({ "1 + 2" })
  feed("v$g=")
  expect({ "3" })

  reset({ "first second" })
  feed("gxiw")
  expect({ "first second" })
  assert(remote("return vim.fn.maparg('<C-c>','n',false,true).desc == 'Stop exchange'"))
  feed("wgxiw")
  expect({ "second first" })
  assert(remote("return vim.fn.maparg('<C-c>','n') == ''"))
  feed("u")
  expect({ "first second" })
  feed("gxiw")
  -- Ctrl-c discards queued input, so wait for cancellation before sending more keys.
  remote("vim.api.nvim_input(vim.api.nvim_replace_termcodes('<C-c>', true, false, true))")
  editor.wait("return vim.fn.maparg('<C-c>','n') == ''")
  expect({ "first second" })
  assert(remote("return vim.fn.maparg('<C-c>','n') == ''"))
  assert(
    remote(
      "return #vim.api.nvim_buf_get_extmarks(0, vim.api.nvim_get_namespaces().MiniOperatorsExchange, 0, -1, {}) == 0"
    )
  )
  reset({ "first" })
  local first_buffer = remote("return vim.api.nvim_get_current_buf()")
  feed("gxx")
  reset({ "second" })
  feed("gxx")
  expect({ "first" })
  assert(vim.deep_equal(remote("return vim.api.nvim_buf_get_lines(...,0,-1,false)", first_buffer), { "second" }))

  reset({ "word" })
  feed("cr<Esc>")
  expect({ "word" })
  remote("vim.bo.modifiable = false")
  feed("gmm")
  expect({ "word" })
  remote("vim.bo.modifiable = true")
  if mode == "available" then
    reset({ "local function value()", "  return 1", "end", "", "print(value())" })
    remote("vim.fn.setreg('a', ...)", "print(2)\n", "V")
    feed('"acraf')
    expect({ "print(2)", "", "print(value())" })
    feed("u")
    expect({ "local function value()", "  return 1", "end", "", "print(value())" })
    feed("saiw)")
    expect({ "(local) function value()", "  return 1", "end", "", "print(value())" })
    feed(" /")
    expect({ "-- (local) function value()", "  return 1", "end", "", "print(value())" })
    assert(remote("return vim.fn.maparg('gci','n',false,true).desc == '[Snacks] Calls incoming'"))
  else
    assert(
      remote(
        "return not package.loaded['mini.ai'] and not package.loaded['mini.comment'] and not package.loaded['mini.surround'] and not package.loaded['blink.cmp'] and not package.loaded.snacks"
      )
    )
  end
end, "Operators checks: " .. mode .. " passed")
