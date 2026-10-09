local editor = dofile(vim.fn.stdpath("config") .. "/tests/editor.lua")
local remote, feed = editor.remote, editor.feed
local mode = assert(vim.env.NVIM_TEST_COMMENTS_MODE)
editor.run(function()
  local status = remote("return require('config.plugins').status().features.comments")
  local function reset(lines, filetype, row)
    feed("<Esc>")
    remote(
      [[
      local lines, filetype, row = ...
      vim.cmd.enew({bang=true})
      vim.bo.filetype = filetype or 'lua'
      vim.api.nvim_buf_set_lines(0,0,-1,false,lines)
      vim.api.nvim_win_set_cursor(0, {row or 1,0})
    ]],
      lines,
      filetype,
      row
    )
  end
  local function expect(lines)
    local actual = remote("return vim.api.nvim_buf_get_lines(0,0,-1,false)")
    assert(vim.deep_equal(actual, lines), vim.inspect({ expected = lines, actual = actual }))
  end
  if mode == "missing" or mode == "disabled" or mode == "core" then
    assert(not status.active and remote("return package.loaded['mini.comment'] == nil"))
    assert(remote("return vim.fn.maparg(' /','n') == '' and vim.fn.maparg(' /','x') == ''"))
    reset({ "local value = 1" })
    feed("gcc")
    expect({ "-- local value = 1" })
    feed("gcc")
    expect({ "local value = 1" })
    return
  end
  assert(status.active and status.available)
  assert(remote("return package.loaded['mini.comment'] ~= nil"))
  reset({ "local value = 1", "print(value)" })
  feed(" /")
  expect({ "-- local value = 1", "print(value)" })
  feed("j.")
  expect({ "-- local value = 1", "-- print(value)" })
  feed("u")
  expect({ "-- local value = 1", "print(value)" })
  feed("k /")
  expect({ "local value = 1", "print(value)" })

  reset({ "first()", "second()", "third()", "fourth()" })
  feed("3 /")
  expect({ "-- first()", "-- second()", "-- third()", "fourth()" })
  feed("3 /")
  expect({ "first()", "second()", "third()", "fourth()" })
  feed("gcj")
  expect({ "-- first()", "-- second()", "third()", "fourth()" })
  feed("u")
  expect({ "first()", "second()", "third()", "fourth()" })

  local block = { "  first()", "    second()", "", "  third()" }
  reset(block)
  feed("V3j /")
  expect({ "  -- first()", "  --   second()", "  --", "  -- third()" })
  assert(remote("return vim.fn.mode() == 'n'"))
  feed("ggV3j /")
  expect(block)
  feed("3GV2k /")
  expect({ "  -- first()", "  --   second()", "  --", "  third()" })
  feed("u")
  expect(block)

  reset({ "-- first()", "second()" })
  feed("gcj")
  expect({ "-- -- first()", "-- second()" })
  feed("gcj")
  expect({ "-- first()", "second()" })
  reset({ "first()", "second()", "", "third()" })
  feed("gcap")
  expect({ "-- first()", "-- second()", "--", "third()" })

  reset({ "start()", "-- first", "-- second", "finish()" }, "lua", 2)
  feed('"aygc')
  assert(remote("return vim.fn.getreg('a')") == "-- first\n-- second\n")
  feed("dgc")
  expect({ "start()", "finish()" })
  feed("u")
  expect({ "start()", "-- first", "-- second", "finish()" })
  feed("vgc<Esc>")
  assert(remote('return vim.fn.line("\'<") == 2 and vim.fn.line("\'>") == 3'))

  reset({ "print('value')" }, "python")
  feed(" /")
  expect({ "# print('value')" })
  feed(" /")
  expect({ "print('value')" })
  reset({ "value" }, "html")
  feed(" /")
  expect({ "<!-- value -->" })
  feed(" /")
  expect({ "value" })
  reset({ "value" }, "text")
  remote("vim.bo.commentstring = '//%s'")
  feed(" /")
  expect({ "// value" })
  feed(" /")
  expect({ "value" })
  remote("vim.bo.commentstring = ''")
  feed(" /")
  expect({ "value" })
  assert(
    remote(
      "return vim.api.nvim_exec2('messages',{output=true}).output:find(\"Option 'commentstring' is empty\",1,true) ~= nil"
    )
  )

  if mode == "available" then
    reset({ "local function value()", "  return 1", "end", "", "print(value())" })
    feed("gcaf")
    expect({ "-- local function value()", "--   return 1", "-- end", "", "print(value())" })
    feed("u")
    expect({ "local function value()", "  return 1", "end", "", "print(value())" })
    assert(remote("return vim.fn.maparg('gci','n',false,true).desc == '[Snacks] Calls incoming'"))
    assert(remote("return vim.fn.maparg('gco','n',false,true).desc == '[Snacks] Calls outgoing'"))
  else
    assert(
      remote(
        "return not package.loaded['mini.ai'] and not package.loaded.catppuccin and not package.loaded['blink.cmp'] and not package.loaded.snacks"
      )
    )
  end
end, "Comments checks: " .. mode .. " passed")
