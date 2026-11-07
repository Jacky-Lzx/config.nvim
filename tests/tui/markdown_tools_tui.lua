local api = vim.api
local result = assert(vim.env.NVIM_STARTUP_RESULT)
local cases, index, checks = {}, 0, 0
local function equal(actual, expected)
  checks = checks + 1
  assert(vim.deep_equal(actual, expected), vim.inspect({ actual = actual, expected = expected }))
end
local function lines()
  return api.nvim_buf_get_lines(0, 0, -1, false)
end
local function reset(text, row, col, ft)
  vim.cmd("enew!")
  vim.bo.swapfile = false
  api.nvim_buf_set_lines(0, 0, -1, false, text)
  vim.bo.filetype = ft or "markdown"
  vim.wo.foldenable = false
  api.nvim_win_set_cursor(0, { row or 1, col or 0 })
  vim.cmd("let &undolevels = &undolevels")
end
local function case(name, input, setup, verify)
  cases[#cases + 1] = { name = name, input = input, setup = setup, verify = verify }
end
case("cold-configuration", " Mx", function()
  local manager = require("config.plugins").manager
  equal(manager.states["markdown-tools.nvim"].phase, "registered")
  assert(not package.loaded.markdown_tools)
  reset({ "- [ ] task", "", "# Title" })
  equal(manager.states["markdown-tools.nvim"].phase, "ready")
  for _, map in ipairs(api.nvim_buf_get_keymap(0, "n")) do
    if (map.rhs or ""):find("<Plug>(MarkdownTools", 1, true) then
      assert(vim.fn.maparg(map.rhs, "n") ~= "", map.rhs)
    end
  end
  assert(not vim.fn.maparg("<CR>", "i"):find("MarkdownTools"))
  assert(not vim.fn.maparg("<Tab>", "i"):find("MarkdownTools"))
end, function()
  equal(lines(), { "- [x] task", "", "# Title" })
  local pos = vim.fn.screenpos(0, 1, 1)
  local text = ""
  for col = pos.col, pos.col + 9 do
    text = text .. vim.fn.screenstring(pos.row, col)
  end
  equal(text, "- [x] task")
end)
case("checkbox-undo", "u", nil, function()
  equal(lines(), { "- [ ] task", "", "# Title" })
end)
case("visual-tasks-code-exclusion", "V5j Mx", function()
  reset({ "- [ ] one", "- [x] two", "", "```md", "- [ ] literal", "```" })
end, function()
  equal(lines(), { "- [x] one", "- [ ] two", "", "```md", "- [ ] literal", "```" })
  equal(vim.fn.mode(), "n")
end)
case("visual-undo", "u", nil, function()
  equal(lines()[1], "- [ ] one")
  equal(lines()[2], "- [x] two")
end)
case("heading-descendants", " Ml", function()
  reset({ "# Parent", "## Child", "text", "# Next" })
end, function()
  equal(lines(), { "## Parent", "### Child", "text", "# Next" })
end)
case("heading-count", "2 M]", nil, function()
  equal(vim.fn.line("."), 4)
end)
case("heading-back", " M[", nil, function()
  equal(vim.fn.line("."), 2)
end)
case("list-item-burst", " Mihello\27", function()
  reset({ "1. [x] old", "  - child", "2. later" })
end, function()
  equal(lines(), { "1. [x] old", "  - child", "2. [ ] hello", "2. later" })
  equal(vim.fn.mode(), "n")
end)
case("list-renumber", " Mn", nil, function()
  equal(lines()[4], "3. later")
end)
case("table-align", " Ma", function()
  reset({ "| 名称 | Value |", "| --- | --- |", "| 中文 | x |" })
end, function()
  equal(lines(), { "| 名称 | Value |", "| ---- | ----- |", "| 中文 | x     |" })
  equal(api.nvim_win_get_cursor(0), { 1, 0 })
end)
case("table-cell", "2 Mj", nil, function()
  equal(vim.fn.line("."), 3)
  equal(vim.fn.col("."), 3)
end)
case("table-row", " Mr", nil, function()
  equal(#lines(), 4)
end)
case("link-anchor", " Mf", function()
  reset({ "# Title", "", "[jump](#title)" }, 3, 3)
end, function()
  equal(vim.fn.line("."), 1)
end)
case("toc", " Mt", function()
  reset({ "", "# Title", "## Child", "# Title" })
end, function()
  assert(table.concat(lines(), "\n"):find("title%-1"))
  equal(lines()[1], "<!-- markdown-tools:toc -->")
end)
case("filetype-isolation", "ix\27", function()
  vim.bo.filetype = "lua"
  equal(vim.fn.exists(":MarkdownToolsOutline"), 0)
  equal(vim.fn.maparg("<Space>Mx", "n"), "")
  reset({ "" }, 1, 0, "lua")
  equal(vim.fn.maparg("<Space>Mx", "n"), "")
end, function()
  equal(lines(), { "x" })
end)
case("adapter-ownership", "0", function()
  reset({ "# Export" })
  local ctx =
    { file = assert(vim.env.NVIM_TEST_TMP) .. "/export.md", filetype = "markdown", buf = api.nvim_get_current_buf() }
  api.nvim_buf_set_name(0, ctx.file)
  ctx.file = api.nvim_buf_get_name(0)
  local peek, task = require("peek"), require("task_tools")
  local open, run = peek.open, task.run
  local previewed, exported
  peek.open = function()
    previewed = true
  end
  task.run = function(spec)
    exported = spec
    return "fixture"
  end
  assert(require("markdown_tools").preview() == nil and previewed)
  equal(require("markdown_tools").export(), false)
  equal(exported, nil)
  vim.bo.modified = false
  equal(require("markdown_tools").export(), "fixture")
  equal(exported.cmd[1], "pandoc")
  equal(exported.cmd[2], ctx.file)
  equal(exported.cmd[4], ctx.file:gsub("%.md$", ".pdf"))
  peek.open, task.run = open, run
  require("languages.markdown.tools").setup(require("config.plugins").options("markdown-tools.nvim"))
  require("languages.markdown.tools").setup(require("config.plugins").options("markdown-tools.nvim"))
  equal(#api.nvim_get_autocmds({ group = "ConfigMarkdownTools" }), 2)
end, function()
  equal(vim.fn.mode(), "n")
end)

local function finish(err)
  vim.fn.writefile(err and vim.split(err, "\n", { plain = true }) or {
    "PASS markdown-tools configured PTY: " .. #cases .. " stages, " .. checks .. " assertions",
  }, result)
  vim.cmd(err and "cquit 1" or "qa!")
end
local function next_case()
  index = index + 1
  if not cases[index] then
    equal(#_G.config_test_errors, 0, table.concat(_G.config_test_errors, "\n"))
    finish()
    return
  end
  local ok, err = xpcall(function()
    if cases[index].setup then
      cases[index].setup()
    end
    vim.cmd("redraw!")
    dofile(vim.env.NVIM_CONFIG_ROOT .. "/tests/support/terminal_input.lua")(cases[index].input, function()
      vim.cmd("redraw!")
      cases[index].verify()
    end, function(error)
      if error then
        finish(cases[index].name .. ": " .. error)
      else
        vim.schedule(next_case)
      end
    end)
    vim.fn.writefile(
      { tostring(index), vim.json.encode(cases[index].input) },
      vim.env.NVIM_TEST_TMP .. "/markdown-stage"
    )
  end, debug.traceback)
  if not ok then
    finish(err)
  end
end
local function start()
  if vim.g.config_ready then
    next_case()
  else
    vim.defer_fn(start, 25)
  end
end
vim.defer_fn(start, 25)
