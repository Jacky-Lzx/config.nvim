local count = 0
local function test(name, callback)
  local ok, err = pcall(function()
    callback()
  end)
  if not ok then
    io.stderr:write("FAIL: " .. name .. "\n" .. tostring(err) .. "\n")
    vim.cmd.cquit(1)
  end
  count = count + 1
  print("PASS: " .. name)
end

local function input(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "xt", false)
end

local function open_fixture(name, lines)
  local path = vim.fs.joinpath(vim.env.NVIM_TEST_TMP, name)
  vim.fn.writefile(lines, path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  return path
end

test("startup discovers the configuration outside its working directory", function()
  assert(vim.v.errmsg == "", vim.v.errmsg)
  assert(vim.fn.exists(":ConfigInfo") == 2)
  assert(vim.fn.getcwd() == vim.fs.joinpath(vim.env.NVIM_TEST_TMP, "work"))
  assert(require("config").info().paths.state == vim.fs.joinpath(vim.env.NVIM_TEST_TMP, "state", "nvim"))
  assert((vim.fn.exists(":Lazy") == 2) == require("config.plugins").status().started)
end)

test("setup can be repeated without duplicating autocommands", function()
  local before = #vim.api.nvim_get_autocmds({ group = "ConfigCore" })
  require("config").setup()
  assert(#vim.api.nvim_get_autocmds({ group = "ConfigCore" }) == before)
end)

test("filetype scripts preserve continuous prose typing", function()
  local fixtures = {
    { "sample.lua", "lua", "-- comment" },
    { "sample.py", "python", "# comment" },
    { "sample.md", "markdown", "# Heading" },
    { "sample.tex", "tex", "\\documentclass{article}" },
  }
  for _, fixture in ipairs(fixtures) do
    open_fixture(fixture[1], { fixture[3] })
    local filetype = fixture[2]
    assert(vim.bo.filetype == filetype, vim.bo.filetype)
    assert(not vim.bo.formatoptions:find("[tcro]"), filetype .. ": " .. vim.bo.formatoptions)
    assert(vim.bo.textwidth == 0, filetype)
    vim.cmd.bwipeout()
  end
  open_fixture("comment.lua", { "" })
  input("i-- comment<CR>body<Esc>")
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "-- comment", "body" }))
  vim.cmd.bwipeout({ bang = true })
end)

test("native Enter and Tab insert without completion or pairing", function()
  open_fixture("input.txt", { "" })
  input("ifirst<CR><Tab>second<Esc>")
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "first", "  second" }))
  vim.cmd.bwipeout({ bang = true })
end)

test("window navigation and wrapping apply to the current window", function()
  vim.cmd.enew()
  local first = vim.api.nvim_get_current_win()
  vim.cmd.vsplit()
  local second = vim.api.nvim_get_current_win()
  input("<C-h>")
  assert(vim.api.nvim_get_current_win() == first)
  input("<C-l>")
  assert(vim.api.nvim_get_current_win() == second)
  input("<A-z>")
  assert(vim.wo[second].wrap)
  assert(not vim.wo[first].wrap)
  vim.cmd.close()
end)

test("bare Visual write saves the entire modified buffer", function()
  local index = 0
  for _, selection in ipairs({ "v", "V", "<C-v>" }) do
    for _, command in ipairs({ "w", "w!", "write", "write!" }) do
      index = index + 1
      local path = open_fixture("save-" .. index .. ".txt", { "first", "second", "third" })
      local expected = { "first", "second", "edited third" }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, expected)
      input("gg" .. selection .. "j:" .. command .. "<CR>")
      assert(vim.deep_equal(vim.fn.readfile(path), expected), selection .. " :" .. command)
      assert(not vim.bo.modified)
    end
  end
end)

test("Visual write exports only the selected lines when given a filename", function()
  open_fixture("export-source.txt", { "first", "second", "third" })
  local output = vim.fs.joinpath(vim.env.NVIM_TEST_TMP, "selection.txt")
  input("ggVj:w " .. vim.fn.fnameescape(output) .. "<CR>")
  assert(vim.deep_equal(vim.fn.readfile(output), { "first", "second" }))
end)

test("Visual substitutions and explicitly ranged writes keep their range", function()
  local path = open_fixture("range.txt", { "first", "second", "third" })
  input("ggVj:s/^/selected-/<CR>")
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "selected-first", "selected-second", "third" }))
  input(":1,2w!<CR>")
  assert(vim.deep_equal(vim.fn.readfile(path), { "selected-first", "selected-second" }))
  vim.cmd.bwipeout({ bang = true })
end)

test("project EditorConfig overrides the default indentation", function()
  local project = vim.fs.joinpath(vim.env.NVIM_TEST_TMP, "project")
  vim.fn.mkdir(project, "p")
  vim.fn.writefile({ "root = true", "[*]", "indent_style = space", "indent_size = 4" }, project .. "/.editorconfig")
  vim.fn.writefile({ "first" }, project .. "/sample.py")
  vim.cmd.edit(vim.fn.fnameescape(project .. "/sample.py"))
  assert(vim.bo.shiftwidth == 4)
  assert(vim.bo.expandtab)
end)

test("external changes reload clean buffers and leave local edits intact", function()
  local path = open_fixture("external.txt", { "before" })
  vim.fn.writefile({ "disk update" }, path)
  vim.api.nvim_exec_autocmds("FocusGained", { buffer = 0 })
  input("<Esc>")
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "disk update" }))

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local edit" })
  vim.fn.writefile({ "another disk update" }, path)
  vim.api.nvim_exec_autocmds("FocusGained", { buffer = 0 })
  input("<Esc>")
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "local edit" }))
  assert(vim.bo.modified)
  vim.cmd.bwipeout({ bang = true })
end)

test("writing saves native undo history in the isolated state directory", function()
  local path = open_fixture("undo.txt", { "before" })
  input("ccafter<Esc>")
  vim.cmd.write()
  assert(vim.fn.filereadable(vim.fn.undofile(path)) == 1)
end)

test("the native file browser remains available", function()
  local directory = vim.fs.joinpath(vim.env.NVIM_TEST_TMP, "work")
  vim.fn.writefile({ "browse fixture" }, directory .. "/fixture.txt")
  vim.cmd.Explore(vim.fn.fnameescape(directory))
  assert(vim.bo.filetype == "netrw" or vim.bo.filetype == "directory", vim.bo.filetype)
  local listing = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  assert(listing:find("fixture.txt", 1, true), listing)
  vim.cmd.bwipeout({ bang = true })
end)

test("configuration information and health run without external dependencies", function()
  vim.cmd.ConfigInfo()
  vim.cmd("checkhealth config")
  local report = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  assert(report:find("Configuration entry:", 1, true), report)
  assert(not report:find("ERROR", 1, true), report)
end)

io.stdout:write(("\nCore checks: %d passed\n"):format(count))
io.stdout:flush()
vim.cmd.qa({ bang = true })
