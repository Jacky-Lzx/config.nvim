-- Real terminal input against the full configuration, including Lazy's cold keys.
local api = vim.api
local directory = assert(vim.env.NVIM_TEST_TMP)
local result = assert(vim.env.NVIM_LAZY_RESULT)
local cases, index, assertions = {}, 0, 0
local function eq(actual, expected, label)
  assertions = assertions + 1
  assert(vim.deep_equal(actual, expected), (label or "assertion") .. ": " .. vim.inspect(actual))
end
local function lines()
  return api.nvim_buf_get_lines(0, 0, -1, false)
end
local function reset(text, cursor, filetype)
  vim.cmd("enew!")
  vim.bo.swapfile = false
  api.nvim_buf_set_lines(0, 0, -1, false, text)
  api.nvim_win_set_cursor(0, cursor or { 1, 0 })
  vim.bo.filetype = filetype or ""
  vim.cmd("let &undolevels = &undolevels")
end
local function case(name, input, setup, verify)
  cases[#cases + 1] = { name = name, input = input, setup = setup, verify = verify }
end
case("cold-object-and-repeat", "cib值\27$h.", function()
  local plugins = require("lazy.core.config").plugins
  eq(not plugins["editing-tools.nvim"]._.loaded, true, "editing must remain cold")
  for _, name in ipairs({ "mini.ai", "mini.align", "mini.operators" }) do
    eq(plugins[name], nil, "legacy editing owner")
  end
  for _, mode in ipairs({ "o", "x" }) do
    for _, key in ipairs({ "ai", "ii" }) do
      eq(vim.fn.maparg(key, mode), "", "no competing scope object")
    end
  end
  reset({ "(one) (two)" }, { 1, 1 })
end, function()
  eq(lines(), { "(值) (值)" })
  eq(require("lazy.core.config").plugins["editing-tools.nvim"]._.loaded ~= nil, true)
  eq(vim.fn.maparg("gX", "n") ~= "", true, "URI fallback")
  eq(vim.fn.mode(), "n")
end)
case("repeat-empty-object", "cibX\27$h.", function()
  reset({ "(a) () ()" }, { 1, 1 })
end, function()
  eq(lines(), { "(X) () (X)" })
end)
case("repeat-after-empty", "0f)2l.", nil, function()
  eq(lines(), { "(X) (X) (X)" })
end)
case("inner-indent-owner", "dii", function()
  reset({ "if ready then", "  first()", "  second()", "end", "tail()" }, { 2, 2 })
end, function()
  eq(lines(), { "if ready then", "end", "tail()" })
end)
case("around-indent-owner", "dai", function()
  reset({ "if ready then", "  first()", "  second()", "end", "tail()" }, { 2, 2 })
end, function()
  eq(lines(), { "end", "tail()" })
end)
case("counted-duplicate", "2gmm", function()
  reset({ "a", "b", "tail" })
end, function()
  eq(lines(), { "a", "b", "a", "b", "tail" })
end)
case("duplicate-undo", "u", nil, function()
  eq(lines(), { "a", "b", "tail" })
end)
case("named-register", '"acriw', function()
  reset({ "word tail" })
  vim.fn.setreg("a", "替换", "v")
end, function()
  eq(lines(), { "替换 tail" })
  eq(vim.fn.getreg("a"), "替换")
end)
case("sort-count", "3gss", function()
  reset({ "c", "a", "b" })
end, function()
  eq(lines(), { "a", "b", "c" })
end)
case("exchange-stage", "gxiw", function()
  reset({ "alpha beta gamma" })
end, function()
  eq(lines(), { "alpha beta gamma" })
  eq(require("editing_tools.exchange").pending(), true)
end)
case("exchange-apply", "wwgxiw", nil, function()
  eq(lines(), { "gamma beta alpha" })
end)
case("exchange-undo", "u", nil, function()
  eq(lines(), { "alpha beta gamma" })
end)
case("alignment-preview", "2gaa", function()
  reset({ "a=1", "long=2", "", "b=3", "larger=4" })
end, function()
  eq(require("editing_tools.align").is_active(), true)
  eq(lines()[1], "a=1", "preview must not modify source")
  local screen = vim.fn.screenpos(0, 1, 1)
  local text = ""
  for col = screen.col, screen.col + 7 do
    text = text .. vim.fn.screenstring(screen.row, col)
  end
  eq(text, "a    = 1", "rendered preview")
end)
case("alignment-cancel", "\27", nil, function()
  eq(require("editing_tools.align").is_active(), false)
  eq(lines()[1], "a=1")
end)
case("alignment-confirm", "2gaa\r", nil, function()
  eq(lines()[1], "a    = 1")
end)
case("alignment-repeat", "3j0.", nil, function()
  eq(lines(), { "a    = 1", "long = 2", "", "b      = 3", "larger = 4" })
  eq(require("editing_tools.align").is_active(), false)
end)
case("lua-function", "dif", function()
  reset({ "function f()", "  local a = 1", "  return a", "end" }, { 2, 3 }, "lua")
end, function()
  eq(lines(), { "function f()", "  ", "end" })
end)
case("rust-query-data", "dif", function()
  reset({ "fn f() {", "    let a = 1;", "    let b = 2;", "    a + b", "}" }, { 3, 4 }, "rust")
end, function()
  eq(lines(), { "fn f() {", "    ", "}" }, "quantified Rust function body")
end)
case("arithmetic", "g==", function()
  reset({ "2 + 3 * 4" })
end, function()
  eq(lines(), { "14" })
end)

local function finish(err)
  vim.fn.writefile(err and vim.split(err, "\n", { plain = true }) or {
    "PASS editing-tools configured PTY: " .. #cases .. " stages, " .. assertions .. " assertions",
  }, result)
  vim.cmd(err and "cquit 1" or "qa!")
end
local function next_case()
  index = index + 1
  if not cases[index] then
    eq(#_G.config_test_errors, 0, table.concat(_G.config_test_errors, "\n"))
    finish()
    return
  end
  local ok, err = xpcall(function()
    if cases[index].setup then
      cases[index].setup()
    end
    vim.cmd("redraw!")
    vim.fn.writefile({ tostring(index), vim.json.encode(cases[index].input) }, directory .. "/editing-stage")
  end, debug.traceback)
  if not ok then
    finish(err)
  end
end
vim.keymap.set("n", "<F12>", function()
  vim.cmd("redraw!")
  local ok, err = xpcall(cases[index].verify, debug.traceback)
  if not ok then
    finish(cases[index].name .. ": " .. err)
    return
  end
  vim.schedule(next_case)
end)
local function start()
  if vim.g.did_very_lazy then
    next_case()
  else
    vim.defer_fn(start, 25)
  end
end
vim.defer_fn(start, 25)
