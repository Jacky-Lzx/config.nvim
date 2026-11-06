local api = vim.api
local vault = assert(vim.env.OBSIDIAN_TEST_VAULT)
local cases, index, assertions = {}, 0, 0
local function eq(actual, expected)
  assertions = assertions + 1
  assert(vim.deep_equal(actual, expected), vim.inspect({ actual = actual, expected = expected }))
end
local original_select, menu, prompt = vim.ui.select, nil, nil
vim.ui.select = function(items, opts, callback)
  prompt = opts.prompt
  menu = original_select(items, opts, callback)
  return menu
end
local function menu_open(title)
  eq(prompt, title)
  assert(menu and not menu.closed and api.nvim_get_current_win() == menu.input_win)
  eq(vim.fn.mode(), "i")
  vim.cmd("redraw!")
  local rows = {}
  for row = 1, vim.o.lines do
    local value = ""
    for col = 1, vim.o.columns do
      value = value .. vim.fn.screenstring(row, col)
    end
    rows[#rows + 1] = value
  end
  assert(table.concat(rows, "\n"):find(title, 1, true), "Picker title was not rendered")
end
local function current(name)
  eq(api.nvim_buf_get_name(0), vault .. "/" .. name)
end
local function lines()
  return api.nvim_buf_get_lines(0, 0, -1, false)
end
local function case(name, input, setup, verify)
  cases[#cases + 1] = { name = name, input = input, setup = setup, verify = verify }
end
case("wiki-completion", "i[[Al", function()
  local graph = require("config.plugins").nodes()
  assert(graph["obsidian-tools.nvim"] and not graph["obsidian.nvim"])
  assert(not package.loaded.obsidian and not package.loaded["obsidian_tools.index"])
  eq(vim.fn.exists(":ObsidianTools"), 2)
end, function()
  local cmp = require("completion-tools")
  assert(cmp.is_menu_visible())
  eq(cmp.get_selected_item().label, "Alpha")
  eq(vim.fn.mode(), "i")
end)
case("wiki-accept", "\r\27", nil, function()
  eq(lines(), { "[[notes/alpha|Alpha]]" })
  eq(vim.fn.mode(), "n")
end)
case("save-completed-link", ":write\r", nil, function()
  eq(vim.bo.modified, false)
end)
case("unified-link-follow", "0 Mf", nil, function()
  current("notes/alpha.md")
  eq(vim.fn.line("."), 1)
end)
case("backlinks", " Ob", nil, function()
  menu_open("Backlinks")
end)
case("backlink-choice", "beta\r", nil, function()
  current("notes/beta.md")
  eq(vim.fn.line("."), 3)
end)
case("quick-switch", " Of", nil, function()
  menu_open("Obsidian notes")
end)
case("quick-switch-choice", "Alpha\r", nil, function()
  current("notes/alpha.md")
end)
case("tags", " Ot", nil, function()
  menu_open("Obsidian tags")
end)
case("tag-choice", "science\r", nil, function()
  menu_open("Tag: #science")
end)
case("tag-note-choice", "Alpha\r", nil, function()
  current("notes/alpha.md")
end)
case("search-prompt", " Og", nil, function()
  eq(vim.fn.mode(), "c")
  eq(vim.fn.getcmdtype(), "@")
end)
case("search-query", "needle\r", nil, function()
  menu_open("Search notes: needle")
end)
case("search-result", "beta\r", nil, function()
  current("notes/beta.md")
  eq(vim.fn.line("."), 4)
end)
case("insert-link", " Ol", nil, function()
  menu_open("Insert note link")
end)
case("insert-link-choice", "Alpha\r", nil, function()
  assert(api.nvim_get_current_line():find("[[notes/alpha|Alpha]]", 1, true))
end)
case("insert-link-undo", "u", nil, function()
  eq(api.nvim_get_current_line(), "needle beta text")
end)
case("new-note-prompt", " On", nil, function()
  eq(vim.fn.mode(), "c")
  eq(vim.fn.getcmdtype(), "@")
end)
case("new-note-create", "Fresh note\r", nil, function()
  assert(api.nvim_buf_get_name(0):match("/notes/%d+%-fresh%-note.md$"))
  assert(vim.fn.filereadable(api.nvim_buf_get_name(0)) == 1)
  assert(table.concat(lines(), "\n"):find("Fresh note", 1, true))
end)
case("daily-create", " ON", nil, function()
  current("dailies/" .. os.date("%Y-%m-%d") .. ".md")
  assert(table.concat(lines(), "\n"):find("DAILY TEMPLATE", 1, true))
  assert(lines()[2]:find(os.date("%Y-%m-%d"), 1, true))
end)
case("template-picker", " OT", nil, function()
  menu_open("Insert template")
end)
local before_template
case("template-insert", "daily-note\r", function()
  before_template =
    api.nvim_buf_get_lines(vim.fn.bufnr(vault .. "/dailies/" .. os.date("%Y-%m-%d") .. ".md"), 0, -1, false)
end, function()
  assert(#lines() > #before_template)
  assert(not table.concat(lines(), "\n"):find("{{", 1, true))
end)
case("template-undo", "u", nil, function()
  eq(lines(), before_template)
end)
case("rename-prompt", " Or", function()
  vim.cmd.edit(vault .. "/notes/alpha.md")
end, function()
  eq(vim.fn.mode(), "c")
  eq(vim.fn.getcmdtype(), "@")
end)
case("rename-and-references", "\21notes/renamed\r", nil, function()
  current("notes/renamed.md")
  eq(vim.fn.filereadable(vault .. "/notes/alpha.md"), 0)
  local beta = table.concat(vim.fn.readfile(vault .. "/notes/beta.md"), "\n")
  assert(beta:find("[[notes/renamed|Alpha]]", 1, true))
  local buf = vim.fn.bufnr(vault .. "/notes/beta.md")
  if api.nvim_buf_is_loaded(buf) then
    assert(table.concat(api.nvim_buf_get_lines(buf, 0, -1, false), "\n"):find("[[notes/renamed|Alpha]]", 1, true))
  end
end)
case("outside-vault", "0", function()
  vim.cmd.edit(vim.env.NVIM_TEST_TMP .. "/outside.md")
  eq(vim.fn.exists(":ObsidianTools"), 0)
  eq(vim.fn.maparg(" OO", "n"), "")
  local selected = require("integrations.completion").options().sources({ bufnr = api.nvim_get_current_buf() })
  eq(vim.tbl_contains(selected, "obsidian"), false)
end, function()
  eq(vim.bo.filetype, "markdown")
end)
local function finish(err)
  vim.ui.select = original_select
  vim.fn.writefile(err and vim.split(err, "\n", { plain = true }) or {
    "PASS native Obsidian PTY: "
      .. #cases
      .. " stages, "
      .. assertions
      .. " assertions; completion, links, pickers, daily/template/new notes, rename and isolation",
  }, vim.env.OBSIDIAN_TEST_RESULT)
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
    local test = cases[index]
    if test.setup then
      test.setup()
    end
    vim.cmd("redraw!")
    dofile(vim.env.NVIM_CONFIG_ROOT .. "/tests/terminal_input.lua")(test.input, test.verify, function(error)
      if error then
        finish(test.name .. ": " .. error)
      else
        vim.schedule(next_case)
      end
    end)
    vim.fn.writefile({ tostring(index), vim.json.encode(test.input) }, vim.env.OBSIDIAN_TEST_STAGE)
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
