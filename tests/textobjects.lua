local editor = dofile(vim.fn.stdpath("config") .. "/tests/editor.lua")
local remote, feed = editor.remote, editor.feed
local mode = vim.env.NVIM_TEST_TEXTOBJECTS_MODE
editor.run(function()
  local status = remote("return require('config.plugins').status().features.textobjects")
  local function reset(lines, filetype, row, col)
    feed("<Esc>")
    remote(
      [[
      local lines, filetype, row, col = ...
      vim.cmd.enew({ bang = true })
      vim.bo.filetype = filetype
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
      vim.api.nvim_win_set_cursor(0, { row, col })
      if filetype == "lua" then vim.treesitter.get_parser(0, "lua"):parse() end
      vim.fn.setreg("a", "")
    ]],
      lines,
      filetype or "text",
      row or 1,
      col or 0
    )
  end
  local function yank(keys, expected)
    feed('"ay' .. keys)
    local result = remote("return vim.fn.getreg('a')")
    assert(result == expected, vim.inspect({ keys = keys, expected = expected, actual = result }))
  end
  if mode == "missing" or mode == "disabled" or mode == "core" then
    assert(not status.active)
    assert(remote("return not package.loaded['mini.ai']"))
    assert(status.enabled == (mode == "missing"))
    reset({ "left (inside) right" }, "text", 1, 7)
    yank("i(", "inside")
    return
  end
  assert(status.active and status.available)
  if mode == "missing-query" then
    local lines = { "function example()", "  return 1", "end" }
    reset(lines, "lua", 2, 4)
    feed("daf")
    assert(vim.deep_equal(remote("return vim.api.nvim_buf_get_lines(0, 0, -1, false)"), lines))
    assert(remote("return vim.fn.mode()") == "n")
    reset({ "plain (words)" }, "text", 1, 8)
    yank("i(", "words")
    remote([[
      local warnings = {}
      vim.health.start = function() end
      vim.health.ok = function() end
      vim.health.info = function() end
      vim.health.warn = function(message) warnings[#warnings + 1] = message end
      require("features.textobjects").check()
      assert(vim.list_contains(warnings, "lua textobject queries are unavailable"))
    ]])
    return
  end
  assert(remote("return require('mini.ai').config.n_lines == 500"))
  for _, key in ipairs({ "a", "i", "an", "in", "al", "il" }) do
    assert(
      remote(
        "local key = ...; return vim.fn.maparg(key, 'o', false, true).desc ~= nil and vim.fn.maparg(key, 'x', false, true).desc ~= nil",
        key
      )
    )
  end
  assert(
    remote(
      "return vim.fn.maparg('g[', 'n', false, true).desc ~= nil and vim.fn.maparg('g]', 'n', false, true).desc ~= nil"
    )
  )
  reset({ "left ( inside ) right" }, "text", 1, 9)
  yank("i(", "inside")
  yank("a(", "( inside )")
  reset({ "call(one, two, three)" }, "text", 1, 12)
  yank("ia", "two")
  reset({ "value 12345 end" }, "text", 1, 8)
  yank("id", "12345")
  reset({ "snake_case CamelCase" }, "text", 1, 8)
  yank("ie", "case")
  reset({ "pkg.call(alpha, beta)" }, "text", 1, 12)
  yank("au", "pkg.call(alpha, beta)")
  yank("aU", "call(alpha, beta)")
  reset({ "<span>inside</span>" }, "text", 1, 8)
  yank("it", "inside")
  reset({ "(one) (two) (three)" }, "text", 1, 2)
  yank("in(", "two")
  reset({ "(one) (two) (three)" }, "text", 1, 9)
  yank("il(", "one")
  reset({ "((nested))" }, "text", 1, 4)
  yank("2a(", "((nested))")
  reset({ "left (inside) right" }, "text", 1, 8)
  feed("g[(")
  assert(remote("return vim.api.nvim_win_get_cursor(0)[2]") == 5)
  feed("g](")
  assert(remote("return vim.api.nvim_win_get_cursor(0)[2]") == 12)
  reset({ "(one) (two)" }, "text", 1, 2)
  feed("di(")
  assert(remote("return vim.api.nvim_get_current_line()") == "() (two)")
  feed("f(l.")
  assert(remote("return vim.api.nvim_get_current_line()") == "() ()")
  feed("u")
  assert(remote("return vim.api.nvim_get_current_line()") == "() (two)")
  reset({ "(one) (two)" }, "text", 1, 2)
  feed("ci(edited<Esc>")
  assert(remote("return vim.api.nvim_get_current_line()") == "(edited) (two)")
  feed("f(l.")
  assert(remote("return vim.api.nvim_get_current_line()") == "(edited) (edited)")

  local function_lines = {
    "local function greet(name)",
    "  print(name)",
    "  return name",
    "end",
    "",
    "function other()",
    "  return 2",
    "end",
  }
  reset(function_lines, "lua", 2, 4)
  yank("af", table.concat({ function_lines[1], function_lines[2], function_lines[3], function_lines[4] }, "\n"))
  yank("if", "print(name)\n  return name")
  reset(function_lines, "lua", 2, 4)
  feed('vaf"ay')
  assert(
    remote("return vim.fn.getreg('a')")
      == table.concat({ function_lines[1], function_lines[2], function_lines[3], function_lines[4] }, "\n")
  )
  reset(function_lines, "lua", 2, 4)
  yank("anf", "function other()\n  return 2\nend")
  reset({ "function empty() end" }, "lua", 1, 10)
  yank("af", "function empty() end")
  reset({ "if enabled then", "  print(1)", "end" }, "lua", 2, 4)
  yank("ao", "if enabled then\n  print(1)\nend")
  yank("io", "print(1)")
  reset({ "for i = 1, 3 do", "  print(i)", "end" }, "lua", 2, 4)
  yank("ao", "for i = 1, 3 do\n  print(i)\nend")
  reset({ "do", "  print(1)", "end" }, "lua", 2, 4)
  yank("ao", "do\n  print(1)\nend")
  reset({ "local f = function()", "  return 1", "end" }, "lua", 2, 4)
  yank("af", "function()\n  return 1\nend")
  reset(function_lines, "lua", 2, 4)
  feed("dif")
  assert(remote("return vim.api.nvim_buf_get_lines(0, 1, 2, false)[1]") == "  ")
  feed("u")
  assert(vim.deep_equal(remote("return vim.api.nvim_buf_get_lines(0, 0, -1, false)"), function_lines))
  reset({ "text without a parser" }, "text")
  feed("daf")
  assert(remote("return vim.api.nvim_get_current_line()") == "text without a parser")
  assert(remote("return vim.fn.mode()") == "n")
  reset({ "plain (words)" }, "text", 1, 8)
  yank("i(", "words")
  if mode == "only" then
    assert(
      remote(
        "return not package.loaded['blink.cmp'] and not package.loaded.snacks and not package.loaded['nvim-treesitter']"
      )
    )
  end
  remote([[
    local warnings = {}
    vim.health.start = function() end
    vim.health.ok = function() end
    vim.health.info = function() end
    vim.health.warn = function(message) warnings[#warnings + 1] = message end
    require("features.textobjects").check()
    assert(#warnings == 0, vim.inspect(warnings))
  ]])
end, "Textobjects checks: " .. mode .. " passed")
