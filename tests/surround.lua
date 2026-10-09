local editor = dofile(vim.fn.stdpath("config") .. "/tests/editor.lua")
local remote, feed = editor.remote, editor.feed
local mode = assert(vim.env.NVIM_TEST_SURROUND_MODE)
editor.run(function()
  local status = remote("return require('config.plugins').status().features.surround")
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
    assert(not status.active and remote("return package.loaded['mini.surround'] == nil"))
    for _, map_mode in ipairs({ "n", "x", "o" }) do
      assert(remote("return vim.fn.maparg('s', ...) == ''", map_mode))
    end
    assert(remote("return vim.fn.maparg('sa','n') == ''"))
    reset({ "word" })
    feed("sX<Esc>")
    expect({ "Xord" })
    feed("u")
    expect({ "word" })
    return
  end
  assert(status.active and status.available)
  assert(remote("return package.loaded['mini.surround'] ~= nil"))
  assert(
    remote(
      "local c = MiniSurround.config; return c.n_lines == 20 and c.search_method == 'cover' and not c.respect_selection_type and c.highlight_duration == 500"
    )
  )
  for _, map_mode in ipairs({ "n", "x", "o" }) do
    assert(remote("return vim.fn.maparg('s', ...) == '<Nop>'", map_mode))
  end
  reset({ "word", "next" })
  feed("s")
  expect({ "word", "next" })
  assert(remote("return vim.fn.mode() == 'n'"))
  feed("saiw)")
  expect({ "(word)", "next" })
  feed("j.")
  expect({ "(word)", "(next)" })
  feed("u")
  expect({ "(word)", "next" })
  feed('ksr)"')
  expect({ '"word"', "next" })
  feed('sd"')
  expect({ "word", "next" })
  feed("u")
  expect({ '"word"', "next" })

  reset({ "word" })
  feed("saiw(")
  expect({ "( word )" })
  feed("sd(")
  expect({ "word" })
  feed("3saiw)")
  expect({ "(((word)))" })
  reset({ "((word))" }, { 1, 2 })
  feed("2sr)]")
  expect({ "[(word)]" })
  feed("sd]")
  expect({ "(word)" })

  reset({ "word" })
  feed("viwsa]")
  expect({ "[word]" })
  feed("u")
  expect({ "word" })
  reset({ "word" }, { 1, 2 })
  feed("v2hsa]")
  expect({ "[wor]d" })
  reset({ "first", "second" })
  feed("Vjsa)")
  expect({ "(first", "second)" })
  feed("sd)")
  expect({ "first", "second" })

  reset({ "word" })
  feed("saiwfwrap<CR>")
  expect({ "wrap(word)" })
  feed("sdf")
  expect({ "word" })
  reset({ "<b>word</b>" }, { 1, 3 })
  feed("srt]")
  expect({ "[word]" })
  reset({ "first (word) second [next] tail" }, { 1, 0 })
  feed("sdn)")
  expect({ "first word second [next] tail" })
  remote("vim.api.nvim_win_set_cursor(0, {1, #vim.api.nvim_get_current_line()-1})")
  feed("sdl]")
  expect({ "first word second next tail" })

  reset({ "(word)" }, { 1, 1 })
  feed("sf)")
  assert(remote("return vim.api.nvim_win_get_cursor(0)[2]") == 5)
  feed("sF)")
  assert(remote("return vim.api.nvim_win_get_cursor(0)[2]") == 0)
  feed("sh)")
  assert(
    remote(
      "return #vim.api.nvim_buf_get_extmarks(0, vim.api.nvim_get_namespaces().MiniSurroundHighlight, 0, -1, {}) == 2"
    )
  )
  editor.wait(
    "return #vim.api.nvim_buf_get_extmarks(0, vim.api.nvim_get_namespaces().MiniSurroundHighlight, 0, -1, {}) == 0"
  )
  feed("sr)<Esc>")
  expect({ "(word)" })
  reset({ "word" })
  feed("saiw<Esc>")
  expect({ "word" })
  feed("sd)")
  expect({ "word" })

  if mode == "available" then
    reset({ "local function value()", "  return 1", "end" })
    feed("saaf)")
    expect({ "(local function value()", "  return 1", "end)" })
    feed("u")
    expect({ "local function value()", "  return 1", "end" })
    feed(" /")
    expect({ "-- local function value()", "  return 1", "end" })
    assert(remote("return vim.fn.maparg('gci','n',false,true).desc == '[Snacks] Calls incoming'"))
  else
    assert(
      remote(
        "return not package.loaded['mini.ai'] and not package.loaded['mini.comment'] and not package.loaded['blink.cmp'] and not package.loaded.snacks"
      )
    )
  end
end, "Surround checks: " .. mode .. " passed")
