local mode = vim.env.NVIM_TEST_GIT_MODE
local repo = vim.fs.joinpath(assert(vim.env.NVIM_TEST_TMP), "git-" .. mode)
vim.fn.mkdir(repo, "p")
local function git(...)
  local args = { "git", "-C", repo }
  vim.list_extend(args, { ... })
  local result = vim.system(args, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  return result.stdout
end
git("init", "--quiet")
local baseline = {}
for i = 1, 30 do
  baseline[i] = ("original line %02d"):format(i)
end
local file = vim.fs.joinpath(repo, "sample.txt")
local other = vim.fs.joinpath(repo, "other.txt")
local function commit(message)
  git("add", ".")
  git(
    "-c",
    "user.name=Config Test",
    "-c",
    "user.email=config-test@example.invalid",
    "-c",
    "commit.gpgsign=false",
    "-c",
    "core.hooksPath=/dev/null",
    "commit",
    "--quiet",
    "-m",
    message
  )
end
local previous = vim.deepcopy(baseline)
previous[1] = "previous revision"
vim.fn.writefile(previous, file)
vim.fn.writefile({ "other baseline", "removed line" }, other)
commit("Initial fixture")
vim.fn.writefile(baseline, file)
commit("Current fixture")
local changed = vim.deepcopy(baseline)
changed[3], changed[4], changed[16], changed[27] =
  "changed three", "changed four", "changed sixteen", "changed twenty seven"
vim.fn.writefile(changed, file)
vim.fn.writefile({ "other baseline" }, other)

local editor = dofile(vim.fn.stdpath("config") .. "/tests/editor.lua")
local remote, feed, wait = editor.remote, editor.feed, editor.wait
editor.run(function()
  remote("vim.cmd.edit(...)", file)
  local unavailable = vim.list_contains({ "missing", "missing-executable", "disabled", "core" }, mode)
  if unavailable then
    assert(remote("return package.loaded.gitsigns == nil"))
    assert(remote("return vim.b.gitsigns_status_dict == nil"))
    assert(remote("return vim.fn.maparg(' ggs', 'n') == ''"))
    local status = remote("return require('config.plugins').status().features.git")
    assert(status.enabled == (mode == "missing" or mode == "missing-executable"))
    local health = remote([[
      local messages = {}
      for _, kind in ipairs({ "start", "info", "ok", "warn", "error" }) do
        vim.health[kind] = function(message) messages[#messages + 1] = message end
      end
      require("features.git").check()
      return table.concat(messages, "\n")
    ]])
    assert(
      health:find(
        mode == "missing" and "Gitsigns is unavailable"
          or mode == "missing-executable" and "Git is unavailable"
          or "Git features are disabled",
        1,
        true
      )
    )
    feed("A text<Esc>")
    assert(remote("return vim.api.nvim_get_current_line()") == "original line 01 text")
    return
  end

  local function hunks(count)
    wait("local h = require('gitsigns').get_hunks(); return h ~= nil and #h == " .. count)
  end
  local function cursor(row)
    remote("vim.api.nvim_win_set_cursor(0, { ..., 0 })", row)
  end
  local function lines()
    return remote("return vim.api.nvim_buf_get_lines(0, 0, -1, false)")
  end
  local function index(expected)
    local ok = vim.wait(10000, function()
      return git("show", ":sample.txt") == table.concat(expected, "\n") .. "\n"
    end, 20)
    assert(ok, "Unexpected Git index content")
  end
  local function marks(predicate)
    wait(
      "for _, m in ipairs(vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, {details=true})) do local d=m[4]; if "
        .. predicate
        .. " then return true end end; return false"
    )
  end
  wait("return vim.b.gitsigns_status_dict ~= nil")
  hunks(3)
  assert(
    remote(
      "local c = require('gitsigns.config').config; return c.numhl and not c.signcolumn and not c.current_line_blame and c.attach_to_untracked"
    )
  )
  marks("d.number_hl_group and d.number_hl_group:find('GitSigns')")
  for _, key in ipairs({
    "]h",
    "]H",
    "[h",
    "[H",
    " ggs",
    " ggr",
    " ggS",
    " ggR",
    " ggp",
    " ggP",
    " ggd",
    " ggD",
    " ggq",
    " ggQ",
    " tgb",
    " tgw",
    " tgs",
  }) do
    assert(remote("return vim.fn.maparg(..., 'n', false, true).buffer == 1", key), key)
  end
  for _, key in ipairs({ " ggs", " ggr", "ih" }) do
    assert(remote("return vim.fn.maparg(..., 'x', false, true).buffer == 1", key), key)
  end
  assert(remote("return vim.fn.maparg('ih', 'o', false, true).buffer == 1"))
  if mode ~= "only" then
    assert(remote("return vim.g.colors_name == 'catppuccin-mocha'"))
    local green = remote("return require('catppuccin.palettes').get_palette('mocha').green")
    assert(remote("return vim.api.nvim_get_hl(0, {name='GitSignsAdd', link=false}).fg") == tonumber(green:sub(2), 16))
  else
    assert(
      remote("return not package.loaded.snacks and not package.loaded['mini.ai'] and not package.loaded['blink.cmp']")
    )
  end

  cursor(1)
  for _, item in ipairs({ { "]h", 3 }, { "]h", 16 }, { "]H", 27 }, { "[h", 16 }, { "[H", 4 } }) do
    feed(item[1])
    wait("return vim.api.nvim_win_get_cursor(0)[1] == " .. item[2])
  end
  cursor(1)
  feed("2]h")
  wait("return vim.api.nvim_win_get_cursor(0)[1] == 16")
  cursor(3)
  feed('"ayih')
  assert(remote("return vim.fn.getreg('a')") == "changed three\nchanged four\n")
  feed("vih<Esc>")
  assert(remote('return vim.fn.line("\'<") == 3 and vim.fn.line("\'>") == 4'))

  cursor(3)
  feed(" ggp")
  wait([[
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative ~= "" then
        local text = table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false), "\n")
        if text:find("changed three", 1, true) and text:find("original line 03", 1, true) then return true end
      end
    end
    return false
  ]])
  remote(
    "for _, w in ipairs(vim.api.nvim_list_wins()) do if vim.api.nvim_win_get_config(w).relative ~= '' then vim.api.nvim_win_close(w, true) end end"
  )
  feed(" ggP")
  marks("d.virt_lines ~= nil or d.hl_group == 'GitSignsAddPreview'")
  feed("<Esc>")

  cursor(3)
  feed(" ggs")
  local staged = vim.deepcopy(baseline)
  staged[3], staged[4] = changed[3], changed[4]
  index(staged)
  hunks(2)
  assert(vim.deep_equal(lines(), changed))
  assert(vim.deep_equal(vim.fn.readfile(file), changed))
  feed(" ggs")
  index(baseline)
  hunks(3)
  cursor(3)
  feed("V ggs<Esc>")
  staged[4] = baseline[4]
  index(staged)
  hunks(3)
  wait("local h = require('gitsigns').get_hunks(); return h ~= nil and h[1] ~= nil and h[1].added.start == 4")
  cursor(3)
  feed("V ggs<Esc>")
  index(baseline)
  hunks(3)
  wait("local h = require('gitsigns').get_hunks(); return h ~= nil and h[1] ~= nil and h[1].added.start == 3")

  cursor(3)
  feed("V ggr<Esc>")
  wait("return vim.api.nvim_buf_get_lines(0, 2, 3, false)[1] == 'original line 03'")
  assert(lines()[4] == changed[4])
  feed("u")
  assert(vim.deep_equal(lines(), changed))
  hunks(3)
  cursor(3)
  feed(" ggr")
  wait("return vim.api.nvim_buf_get_lines(0, 3, 4, false)[1] == 'original line 04'")
  assert(lines()[16] == changed[16])
  assert(vim.deep_equal(vim.fn.readfile(file), changed))
  feed("u")
  hunks(3)
  assert(vim.deep_equal(lines(), changed))
  feed(" ggS")
  index(changed)
  hunks(0)
  local unstaged = vim.deepcopy(changed)
  for i, row in ipairs({ 3, 16, 27 }) do
    cursor(row)
    feed(" ggs")
    unstaged[row] = baseline[row]
    if row == 3 then
      unstaged[4] = baseline[4]
    end
    index(unstaged)
    hunks(i)
  end
  cursor(3)
  feed(" ggR")
  wait("return vim.api.nvim_get_current_line() == 'original line 03'")
  assert(vim.deep_equal(lines(), baseline))
  feed("u")
  hunks(3)
  assert(vim.deep_equal(lines(), changed))

  cursor(3)
  feed(" tgs")
  assert(remote("return require('gitsigns.config').config.signcolumn"))
  marks("d.sign_text ~= nil")
  feed(" tgs")
  assert(remote("return not require('gitsigns.config').config.signcolumn"))
  feed(" tgw")
  assert(remote("return require('gitsigns.config').config.word_diff"))
  assert(remote("return next(vim.api.nvim_get_hl(0, {name='GitSignsChangeInline', link=false})) ~= nil"))
  feed(" tgw")
  cursor(1)
  feed(" tgb")
  wait("return vim.b.gitsigns_blame_line_dict ~= nil and vim.b.gitsigns_blame_line_dict.author == 'Config Test'")
  marks("d.virt_text ~= nil and m[2] == 0")
  feed(" tgb")
  assert(remote("return not require('gitsigns.config').config.current_line_blame"))

  remote("vim.cmd.write()")
  feed(" ggq")
  wait("return #vim.fn.getqflist() == 3 and vim.bo.buftype == 'quickfix'")
  assert(remote("local q=vim.fn.getqflist(); return q[1].lnum==3 and q[2].lnum==16 and q[3].lnum==27"))
  remote("vim.cmd.cclose()")
  remote("vim.cmd.cd(...)", repo)
  feed(" ggQ")
  wait("return #vim.fn.getqflist() == 4 and vim.bo.buftype == 'quickfix'")
  remote("vim.cmd.cclose()")

  for _, item in ipairs({ { " ggd", baseline }, { " ggD", previous } }) do
    feed(item[1])
    wait("return vim.wo.diff and #vim.api.nvim_list_wins() == 2")
    assert(remote(
      [[
      local expected = ...
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        if vim.list_contains({ "acwrite", "nowrite" }, vim.bo[vim.api.nvim_win_get_buf(w)].buftype) then
          return vim.deep_equal(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(w), 0, -1, false), expected)
        end
      end
      return false
    ]],
      item[2]
    ))
    for _, key in ipairs({ "]h", "]H", "[h", "[H" }) do
      cursor(10)
      remote("vim.cmd.normal({ ..., bang = true })", key)
      local native = remote("return vim.api.nvim_win_get_cursor(0)")
      cursor(10)
      feed(key)
      assert(vim.deep_equal(remote("return vim.api.nvim_win_get_cursor(0)"), native))
    end
    remote([[
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        if vim.list_contains({ "acwrite", "nowrite" }, vim.bo[vim.api.nvim_win_get_buf(w)].buftype) then
          vim.api.nvim_set_current_win(w)
          break
        end
      end
    ]])
    feed("qq")
    wait("return not vim.wo.diff and #vim.api.nvim_list_wins() == 1")
  end

  local untracked = vim.fs.joinpath(repo, "new.txt")
  vim.fn.writefile({ "new content" }, untracked)
  remote("vim.cmd.edit(...)", untracked)
  wait("return vim.b.gitsigns_status_dict ~= nil and vim.b.gitsigns_status_dict.added == 1")
  assert(remote("return vim.fn.maparg(' ggs', 'n', false, true).buffer == 1"))
  marks("d.number_hl_group and d.number_hl_group:find('GitSignsUntracked')")
  remote("vim.cmd.edit(...)", other)
  wait("return vim.b.gitsigns_status_dict ~= nil and vim.b.gitsigns_status_dict.removed == 1")
  marks("d.number_hl_group and d.number_hl_group:find('GitSignsDelete')")
  local plain = vim.fs.joinpath(vim.env.NVIM_TEST_TMP, "plain-" .. mode .. ".txt")
  vim.fn.writefile({ "plain content" }, plain)
  remote("vim.cmd.edit(...)", plain)
  wait("return vim.b.gitsigns_status_dict == nil")
  assert(remote("return vim.fn.maparg(' ggs', 'n') == '' and vim.fn.maparg(' tgb', 'n') == ''"))
end, "Git checks: " .. mode .. " passed")
