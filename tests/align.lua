local editor = dofile(vim.fn.stdpath("config") .. "/tests/editor.lua")
local remote, feed = editor.remote, editor.feed
local mode = assert(vim.env.NVIM_TEST_ALIGN_MODE)
editor.run(function()
  local status = remote("return require('config.plugins').status().features.align")
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
    assert(not status.active and remote("return package.loaded['mini.align'] == nil"))
    for _, map_mode in ipairs({ "n", "x" }) do
      assert(
        remote("local mode = ...; return vim.fn.maparg('ga', mode) == '' and vim.fn.maparg('gA', mode) == ''", map_mode)
      )
    end
    reset({ "word" })
    feed("ga")
    expect({ "word" })
    assert(remote("return vim.fn.mode() == 'n'"))
    return
  end
  assert(status.active and status.available)
  assert(remote("return package.loaded['mini.align'] ~= nil"))
  assert(
    remote("return MiniAlign.config.mappings.start == 'gA' and MiniAlign.config.mappings.start_with_preview == 'ga'")
  )
  local original = { "a=1", "long=2" }
  local aligned = { "a    = 1", "long = 2" }
  reset(original)
  feed("ggVjgA=")
  expect(aligned)
  assert(remote("return vim.fn.mode() == 'n'"))
  feed("u")
  expect(original)
  feed("ggVjga=<CR>")
  expect(aligned)
  feed("u")
  expect(original)
  feed("ggVjga=<Esc>")
  expect(original)

  -- Observe a live preview, then finish it through the editor's input queue.
  remote(
    [[
    local expected = ...
    _G.config_align_preview = nil
    local attempts = 0
    local function observe()
      attempts = attempts + 1
      local lines = vim.api.nvim_buf_get_lines(0,0,-1,false)
      if vim.deep_equal(lines, expected) or attempts == 100 then
        _G.config_align_preview = lines
        vim.api.nvim_input(vim.api.nvim_replace_termcodes('<Esc>',true,false,true))
      else
        vim.defer_fn(observe, 20)
      end
    end
    vim.defer_fn(observe, 20)
    vim.api.nvim_input('ggVjga=')
  ]],
    aligned
  )
  editor.wait("return _G.config_align_preview ~= nil and vim.fn.mode() == 'n'")
  assert(vim.deep_equal(remote("return _G.config_align_preview"), aligned))
  expect(original)

  reset({ "a=1", "long=2", "", "b=3", "longer=4" })
  feed("gAj=")
  expect({ "a    = 1", "long = 2", "", "b=3", "longer=4" })
  remote("vim.api.nvim_win_set_cursor(0,{4,0})")
  feed(".")
  expect({ "a    = 1", "long = 2", "", "b      = 3", "longer = 4" })
  feed("u")
  expect({ "a    = 1", "long = 2", "", "b=3", "longer=4" })
  reset(original, { 2, 0 })
  feed("VkgA=")
  expect(aligned)
  reset({ "  a=1", "  long=2" })
  feed("ggVjgA=")
  expect({ "  a    = 1", "  long = 2" })
  reset({ "a:x", "long:y" })
  feed("ggVjgA:")
  expect({ "a   :x", "long:y" })
  reset({ "a:x", "long:y" })
  feed("ggVjgas:<CR>jr<CR>")
  expect({ "   a:x", "long:y" })
  reset({ "a:x", "long:y" })
  feed("ggVjgas:<CR>m | <CR><CR>")
  expect({ "a    | : | x", "long | : | y" })

  if mode == "available" then
    reset({ "local function value()", "  a=1", "  long=2", "end" })
    feed("gAaf=")
    expect({ "local function value()", "  a    = 1", "  long = 2", "end" })
    feed("u")
    expect({ "local function value()", "  a=1", "  long=2", "end" })
    feed("gmm")
    expect({ "local function value()", "local function value()", "  a=1", "  long=2", "end" })
    assert(remote("return vim.fn.maparg('gci','n',false,true).desc == '[Snacks] Calls incoming'"))
  else
    assert(
      remote(
        "return not package.loaded['mini.ai'] and not package.loaded['mini.operators'] and not package.loaded['mini.comment'] and not package.loaded['mini.surround'] and not package.loaded['blink.cmp'] and not package.loaded.snacks"
      )
    )
  end
end, "Align checks: " .. mode .. " passed")
