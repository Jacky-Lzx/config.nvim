local mode = assert(vim.env.NVIM_TEST_UI_MODE)
local editor = dofile(vim.fn.stdpath("config") .. "/tests/editor.lua")
local remote, feed, wait = editor.remote, editor.feed, editor.wait
local directory = vim.fs.joinpath(assert(vim.env.NVIM_TEST_TMP), "ui-" .. mode)
vim.fn.mkdir(directory, "p")
local files = {}
for i = 1, 9 do
  files[i] = vim.fs.joinpath(directory, "file" .. i .. ".txt")
  vim.fn.writefile({ "first line", "second line", "third line" }, files[i])
end

editor.run(function()
  local statusline = not vim.list_contains({ "missing", "buffers", "buffers-only", "disabled", "core" }, mode)
  local buffers = not vim.list_contains({ "missing", "statusline", "statusline-only", "disabled", "core" }, mode)
  if statusline then
    wait("return package.loaded.lualine ~= nil")
  else
    assert(
      remote(
        "return package.loaded.lualine == nil and vim.wo.statusline == vim.api.nvim_get_option_info2('statusline', {}).default and vim.wo.winbar == ''"
      )
    )
  end
  if buffers then
    wait("return vim.fn.exists(':BufferNext') == 2")
  else
    assert(remote("return package.loaded.barbar == nil and vim.fn.exists(':BufferNext') == 0"))
    assert(remote("return vim.fn.maparg('<A-w>', 'n') == ''"))
  end
  remote("vim.cmd.edit(...)", files[1])
  local function render(option)
    return remote(
      [[
      local option = ...
      if package.loaded.lualine then require('lualine').refresh({ force=true }) end
      vim.cmd.redraw()
      return vim.api.nvim_eval_statusline(option == 'tabline' and vim.o.tabline or vim.wo[option], {
        winid = vim.api.nvim_get_current_win(), maxwidth = 240, use_tabline = option == 'tabline', use_winbar = option == 'winbar',
      }).str
    ]],
      option
    )
  end
  local function contains(option, text)
    local actual = render(option)
    assert(actual:find(text, 1, true), vim.inspect({ option = option, expected = text, actual = actual }))
    local screen = editor.screen()
    assert(screen:find(text, 1, true), screen)
  end
  if statusline then
    contains("statusline", "NORMAL")
    contains("statusline", "file1.txt")
    contains("statusline", "utf-8")
    contains("winbar", "file1.txt")
    feed("i")
    contains("statusline", "INSERT")
    feed("text<Esc>")
    contains("statusline", "[+]")
    remote("vim.cmd.write()")
    assert(not render("statusline"):find("[+]", 1, true))
    remote([[
      local ns = vim.api.nvim_create_namespace('config_ui_diagnostics')
      vim.diagnostic.set(ns, 0, {
        { lnum = 0, col = 0, message = 'Test error', severity = vim.diagnostic.severity.ERROR },
        { lnum = 1, col = 0, message = 'Test warning', severity = vim.diagnostic.severity.WARN },
      })
    ]])
    local icons = remote("return require('lualine').get_config().options.icons_enabled")
    contains("statusline", icons and "󰅚 1" or "E:1")
    contains("statusline", icons and "󰀪 1" or "W:1")
    assert(
      remote("local s=require('lualine').get_config().sections.lualine_b[3]; return s.sources[1]=='nvim_diagnostic'")
    )
    feed("qa")
    assert(remote("return vim.fn.reg_recording() == 'a'"))
    contains("statusline", "󰑋 a")
    feed("q")
    assert(remote("return vim.fn.reg_recording() == ''"))
    assert(not render("statusline"):find("󰑋", 1, true))
    remote("vim.diagnostic.reset(vim.api.nvim_get_namespaces().config_ui_diagnostics, 0)")
    if mode == "statusline-only" then
      assert(remote("return vim.g.colors_name == 'habamax' and not package.loaded.catppuccin"))
      assert(remote("return require('lualine').get_config().options.theme == 'auto'"))
    end
  end

  if buffers then
    wait("return vim.o.showtabline == 0")
    for i = 2, 9 do
      remote("vim.cmd.edit(...)", files[i])
    end
    wait("return vim.o.showtabline == 2 and #require('barbar.state').buffers == 9")
    contains("tabline", "file1.txt")
    contains("tabline", "file9.txt")
    for i = 1, 9 do
      feed("<A-" .. i .. ">")
      assert(remote("return vim.api.nvim_buf_get_name(0)") == files[i])
    end
    for _, item in ipairs({ { "<A-h>", 8 }, { "<A-l>", 9 }, { "]b", 1 }, { "[b", 9 } }) do
      feed(item[1])
      assert(remote("return vim.api.nvim_buf_get_name(0)") == files[item[2]])
    end
    for _, key in ipairs({ "<A-S-,>", "<A-S-.>", "<A-<>", "<A->>" }) do
      local previous = remote("return vim.deepcopy(require('barbar.state').buffers)")
      local position = remote("return vim.fn.index(require('barbar.state').buffers, vim.api.nvim_get_current_buf())")
      feed(key)
      local next_position =
        remote("return vim.fn.index(require('barbar.state').buffers, vim.api.nvim_get_current_buf())")
      assert(
        next_position == position + ((key:find(",", 1, true) or key == "<A-<>") and -1 or 1),
        vim.inspect({ key = key, position = position, actual = next_position, previous = previous })
      )
    end
    remote("vim.cmd.split()")
    local windows = remote("return #vim.api.nvim_list_wins()")
    local closed = remote("return vim.api.nvim_buf_get_name(0)")
    feed("<A-w>")
    assert(remote("return #vim.api.nvim_list_wins()") == windows)
    assert(remote("return vim.api.nvim_buf_get_name(0)") ~= closed)
    feed("<A-u>")
    wait("return vim.api.nvim_buf_get_name(0) == " .. string.format("%q", closed))
    assert(remote("return #vim.api.nvim_list_wins()") == windows)
    feed("A changed<Esc>")
    contains("tabline", "file9.txt")
    local prior_errors = remote("return #_G.config_test_errors")
    feed("<A-w><Esc>")
    assert(remote("return vim.bo.modified"))
    assert(remote("return vim.api.nvim_buf_get_name(0)") == closed)
    remote(
      [[
      local prior = ...
      for i = #_G.config_test_errors, prior + 1, -1 do
        assert(_G.config_test_errors[i]:find('E89: No write since last change', 1, true), _G.config_test_errors[i])
        table.remove(_G.config_test_errors, i)
      end
    ]],
      prior_errors
    )
    remote("vim.cmd.write(); vim.cmd.only()")
    local all = remote("return vim.deepcopy(require('barbar.state').buffers)")
    for _, bufnr in ipairs(all) do
      if remote("return vim.api.nvim_get_current_buf() ~= ...", bufnr) then
        remote("vim.cmd.bdelete(...)", bufnr)
      end
    end
    wait("return #require('barbar.state').buffers == 1 and vim.o.showtabline == 0")
    remote("vim.cmd.tabnew(); vim.cmd.edit(...)", files[1])
    wait("return vim.o.showtabline == 2")
    remote("vim.cmd.tabclose()")
  end

  if statusline or buffers then
    local expected_icons = not vim.list_contains({ "statusline", "buffers", "missing-icons" }, mode)
    if statusline then
      assert(remote("return require('lualine').get_config().options.icons_enabled") == expected_icons)
    end
    if buffers then
      assert(remote("return require('barbar.config').options.icons.filetype.enabled") == expected_icons)
    end
    assert(remote("return require('features.ui.icons').available()") == expected_icons)
    if mode == "available" or mode == "missing-icons" then
      local function git(args)
        local result = vim.system(vim.list_extend({ "git", "-C", directory }, args), { text = true }):wait()
        assert(result.code == 0, result.stderr)
      end
      git({ "init", "--quiet", "--initial-branch=ui%test" })
      git({ "add", "." })
      git({
        "-c",
        "user.name=Config Test",
        "-c",
        "user.email=test@example.invalid",
        "-c",
        "commit.gpgsign=false",
        "-c",
        "core.hooksPath=/dev/null",
        "commit",
        "--quiet",
        "-m",
        "UI fixture",
      })
      vim.fn.writefile({ "modified", "second line", "third line", "added" }, files[1])
      remote("vim.cmd.edit(...); vim.cmd.checktime()", files[1])
      wait(
        "return vim.b.gitsigns_status_dict ~= nil and vim.b.gitsigns_status_dict.changed == 1 and vim.b.gitsigns_status_dict.added == 1"
      )
      contains("statusline", "ui%test")
      contains("statusline", "+1")
      contains("statusline", "~1")
    end
    if buffers and mode == "available" then
      local text = remote([[
        local mocha = require('catppuccin.palettes').get_palette('mocha')
        assert(vim.api.nvim_get_hl(0, {name='BufferCurrent', link=false}).fg == tonumber(mocha.text:sub(2),16))
        vim.cmd.colorscheme('habamax')
        vim.cmd.colorscheme('catppuccin-nvim')
        return vim.api.nvim_get_hl(0, {name='BufferCurrent', link=false})
      ]])
      assert(text.fg ~= nil)
    end
    if statusline and mode == "available" and vim.env.NVIM_TEST_UI_LIVE == "1" then
      local lua = vim.fs.joinpath(directory, "sample.lua")
      vim.fn.writefile({ "local value = 1", "print(value)" }, lua)
      remote("vim.cmd.edit(...)", lua)
      wait(
        "for _, c in ipairs(vim.lsp.get_clients({bufnr=0})) do if c.name=='lua_ls' and c.initialized then return true end end; return false",
        30000
      )
      contains("winbar", "lua_ls")
    end
  else
    feed("ihello<Esc>")
    assert(remote("return vim.api.nvim_get_current_line()") == "hellofirst line")
  end
end, "UI checks: " .. mode .. " passed")
