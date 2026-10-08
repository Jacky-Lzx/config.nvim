local editor = dofile(vim.fn.stdpath("config") .. "/tests/editor.lua")
local remote, feed = editor.remote, editor.feed
local mode = vim.env.NVIM_TEST_TREESITTER_MODE
editor.run(
  function()
    local status = remote("return require('features.treesitter').status()")
    assert(remote("return vim.fn.exists(':TSInstallConfigured') == 2"))
    if mode == "core" or mode == "disabled" or mode == "no-languages" then
      assert(#status.parsers == 0)
      if mode == "no-languages" then
        assert(status.enabled and status.active)
        assert(remote("return require('features.treesitter.install').run() == nil"))
      else
        assert(not status.enabled and not status.active)
        assert(remote("return not package.loaded['nvim-treesitter']"))
        assert(remote("return #vim.api.nvim_get_autocmds({group = 'ConfigTreesitter'}) == 0"))
      end
      return
    end
    assert(status.enabled and #status.parsers == 1 and status.parsers[1].name == "lua")
    if mode == "missing-plugin" or mode == "missing-parser" then
      assert(not status.parsers[1].installed)
      assert(status.active == (mode == "missing-parser"))
      remote([[
      local warnings = {}
      vim.health.start = function() end
      vim.health.ok = function() end
      vim.health.info = function() end
      vim.health.warn = function(message) warnings[#warnings + 1] = message end
      require("features.treesitter.health").check()
      assert(vim.list_contains(warnings, "lua managed parser is missing or outdated"))
      if vim.env.NVIM_TEST_TS_TOOLS == "missing" then
        local notifications = {}
        vim.notify = function(message, level) notifications[#notifications + 1] = { message, level } end
        assert(require("features.treesitter.install").run() == nil)
        assert(notifications[1][1]:find("tree-sitter", 1, true))
        assert(notifications[1][2] == vim.log.levels.WARN)
        assert(vim.fn.filereadable(require("features.treesitter").status().parsers[1].path) == 0)
      end
    ]])
    else
      assert(status.active and status.parsers[1].installed)
      remote([[
      local status = require("features.treesitter").status()
      assert(vim.api.nvim_get_runtime_file("parser/lua.*", false)[1] == status.parsers[1].path)
      assert(vim.treesitter.query.get_files("lua", "highlights")[1] == status.install_dir .. "/queries/lua/highlights.scm")
      local before = vim.uv.fs_stat(status.parsers[1].path).mtime
      assert(require("features.treesitter.install").run() == nil)
      assert(vim.deep_equal(before, vim.uv.fs_stat(status.parsers[1].path).mtime))
      local count = #vim.api.nvim_get_autocmds({group = "ConfigTreesitter"})
      require("config").setup()
      assert(#vim.api.nvim_get_autocmds({group = "ConfigTreesitter"}) == count)
    ]])
    end
    local path = vim.env.NVIM_TEST_TMP .. "/syntax.lua"
    vim.fn.writefile({ "local M = {}", "function M.greet(name)", '  return "hello " .. name', "end", "return M" }, path)
    remote("vim.cmd.edit(...)", path)
    remote([[
    local parser = assert(vim.treesitter.get_parser(0, "lua"))
    assert(not parser:parse()[1]:root():has_error())
    assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()])
    local function capture(row, col, name)
      for _, item in ipairs(vim.treesitter.get_captures_at_pos(0, row, col)) do
        if item.capture == name then return true end
      end
      return false
    end
    assert(capture(1, 13, "function"), "Function capture is missing")
    assert(capture(2, 11, "string"), "String capture is missing")
    if vim.g.colors_name == "catppuccin-mocha" then
      assert(vim.api.nvim_get_hl(0, { name = "@function.lua", link = false }).fg == 0x89b4fa)
      assert(vim.api.nvim_get_hl(0, { name = "@string.lua", link = false }).fg == 0xa6e3a1)
    end
  ]])
    feed('gg2j0f"ci"hi<Esc>')
    assert(remote("return vim.api.nvim_buf_get_lines(0, 2, 3, false)[1]") == '  return "hi" .. name')
    assert(remote("return not vim.treesitter.get_parser(0, 'lua'):parse()[1]:root():has_error()"))
    if mode == "only" then
      assert(remote("return not package.loaded['blink.cmp'] and not package.loaded.snacks"))
      remote([[
      local record = require("languages.lua")
      local parser = record.parser
      record.parser = "config_absent_parser"
      require("features.treesitter").start(vim.api.nvim_get_current_buf())
      record.parser = parser
      assert(not vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()])
      assert(vim.bo.syntax == "lua" and vim.b.current_syntax == "lua")
    ]])
      feed("A -- native editing<Esc>")
      assert(remote("return vim.api.nvim_get_current_line():find('native editing', 1, true) ~= nil"))
    end
    remote("vim.bo.modified = false; vim.cmd.enew(); vim.bo.filetype = 'text'")
    assert(remote("return not vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()]"))
  end,
  "Tree sitter checks: " .. mode .. (vim.env.NVIM_TEST_TS_TOOLS and " (installation tools missing)" or "") .. " passed"
)
