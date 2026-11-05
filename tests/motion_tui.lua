-- Actual configured mappings, driven by terminal bytes in tests/tui.py.
local plugins = require("config.plugins").nodes()
local result = assert(vim.env.NVIM_STARTUP_RESULT)
local stage = assert(vim.env.NVIM_TEST_TMP) .. "/motion-stage"
local motion = require("motion_tools")
local View = require("motion_tools.view")
local Session = require("motion_tools.session")
local cases, index, finished = {}, 0, false
local source, buffer
local function at(row, col)
  assert(vim.deep_equal(vim.api.nvim_win_get_cursor(0), { row, col }), vim.inspect(vim.api.nvim_win_get_cursor(0)))
end
local function text()
  return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
end
local function reset(lines, cursor)
  vim.cmd.normal({ vim.keycode("<Esc>"), bang = true })
  vim.api.nvim_set_current_win(source)
  vim.cmd("only!")
  vim.api.nvim_win_set_buf(source, buffer)
  vim.bo.filetype = ""
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines or { "alpha beta gamma", "  beta", "tail" })
  vim.api.nvim_win_set_cursor(source, cursor or { 1, 0 })
  vim.fn.setreg("/", "previous-search")
  require("notification-tools").dismiss()
end
local function case(name, input, setup, verify)
  cases[#cases + 1] = { name = name, input = input, setup = setup or reset, verify = verify }
end
case("jump", " fgam\r", nil, function()
  at(1, 11)
  assert(vim.fn.getreg("/") == "previous-search")
end)
case("operator", "d fgam\r", nil, function()
  assert(text() == "gamma\n  beta\ntail")
end)
case("register", '"ay fgam\r', nil, function()
  assert(vim.fn.getreg("a") == "alpha beta ")
end)
case("cancel", "d fbeta\27", nil, function()
  at(1, 0)
  assert(text() == "alpha beta gamma\n  beta\ntail")
end)
case("visual", "v fgam\r", nil, function()
  assert(vim.fn.mode() == "v")
  at(1, 11)
  assert(vim.fn.getpos("v")[3] == 1)
end)
case("line", " jd", nil, function()
  at(3, 0)
end)
case("repeat", "d fgam\raj0.", function()
  reset({ "alpha beta gamma", "alpha beta gamma" })
end, function()
  assert(text() == "gamma\ngamma")
end)
case("search", "/beta\r", nil, function()
  at(1, 6)
  assert(
    #vim.api.nvim_buf_get_extmarks(buffer, require("motion_tools.search").ns, 0, -1, {}) == 1,
    "Native / lens missing"
  )
end)
case("search-count", "2n", function()
  reset({ "beta beta beta beta" })
  vim.fn.setreg("/", "beta")
  vim.v.searchforward = 1
end, function()
  at(1, 10)
end)
case("search-label", "/beta\6s", nil, function()
  at(2, 2)
  assert(vim.fn.getreg("/") == "beta")
end)
case("search-cancel", "/beta\6\27", nil, function()
  at(1, 0)
  assert(vim.fn.getreg("/") == "previous-search")
end)
case("indent", "2]i", function()
  reset({ "root", "  child", "    grandchild", "tail" })
end, function()
  at(3, 4)
end)
case("diagnostic", "2]d", function()
  reset({ "one", "two", "three", "four" })
  vim.diagnostic.set(vim.api.nvim_create_namespace("MotionConfigured"), buffer, {
    { lnum = 1, col = 0, message = "first" },
    { lnum = 3, col = 0, message = "second" },
  })
end, function()
  at(4, 0)
end)
local remote
case("cross-window", " ftarget\r", function()
  reset({ "source" })
  vim.cmd("vnew")
  remote = vim.api.nvim_get_current_win()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "remote target" })
  vim.api.nvim_set_current_win(source)
end, function()
  assert(vim.api.nvim_get_current_win() == remote)
  at(1, 7)
end)
local function lua_source()
  reset({ "local word = '中文'", "print(word)" }, { 1, 7 })
  vim.bo.filetype = "lua"
end
case("syntax-ancestor", " Fa", lua_source, function()
  assert(vim.fn.mode() == "v")
  at(1, 9)
  assert(vim.fn.getpos("v")[3] == 7)
end)
case("syntax-operator-search", '"ay Fword\ra', lua_source, function()
  assert(vim.fn.getreg("a") == "word")
end)
case("syntax-visual-search", "v Fword\ra", lua_source, function()
  assert(vim.fn.mode() == "v")
  at(1, 9)
end)

local function finish(ok, message)
  if finished then
    return
  end
  finished = true
  vim.fn.writefile(vim.split(message, "\n", { plain = true }), result)
  vim.cmd(ok and "qa!" or "cquit 1")
end
local function advance()
  index = index + 1
  if index > #cases then
    for _, name in ipairs({ "flash.nvim", "nvim-hlslens", "mini.bracketed" }) do
      assert(not plugins[name], "Competing plugin remains: " .. name)
    end
    for _, name in ipairs({ "flash", "hlslens", "mini.bracketed" }) do
      assert(not package.loaded[name], name)
    end
    for _, entry in ipairs(require("notification-tools").history()) do
      assert(not entry.message:find("motion-tools find:", 1, true), "Prompt leaked into notifications")
      assert(not entry.message:find("motion-tools label:", 1, true), "Label prompt leaked into notifications")
    end
    assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
    finish(true, "Configured motion checks passed: " .. #cases .. " real terminal workflows")
    return
  end
  cases[index].setup()
  vim.fn.writefile({ tostring(index), vim.json.encode(cases[index].input) }, stage)
end
vim.keymap.set({ "n", "x" }, "<F12>", function()
  vim.schedule(function()
    local ok, err = xpcall(function()
      assert(not Session.active and not View.prompt_win and not View.panel_win, "Motion UI leaked")
      cases[index].verify()
      advance()
    end, debug.traceback)
    if not ok then
      finish(false, cases[index].name .. ": " .. err)
    end
  end)
end)
vim.api.nvim_create_autocmd("User", {
  pattern = "ConfigReady",
  once = true,
  callback = function()
    vim.defer_fn(function()
      local ok, err = xpcall(function()
        assert(require("config.plugins").initialized("motion-tools.nvim"), "Motion feedback must load at startup")
        assert(require("motion_tools.config").options.mappings == false, "Config must own explicit mappings")
        for _, mode in ipairs({ "n", "x", "o" }) do
          for _, lhs in ipairs({ " f", " F", " j", " k", "]i", "[i", "]o", "[o", "]d", "[d", "]t", "[t" }) do
            local map = vim.fn.maparg(lhs, mode, false, true)
            assert(map.callback and map.desc:find("[Motion]", 1, true), mode .. " " .. lhs)
          end
        end
        assert(vim.fn.maparg("<C-f>", "c", false, true).expr == 1)
        for _, lhs in ipairs({ "[b", "]b" }) do
          assert(vim.fn.maparg(lhs, "n", false, true).desc:find("[Buffer]", 1, true), "Bufferline mapping replaced")
        end
        vim.cmd("enew!")
        source, buffer = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
        advance()
      end, debug.traceback)
      if not ok then
        finish(false, err)
      end
    end, 100)
  end,
})
