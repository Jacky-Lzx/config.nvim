local editor = dofile(vim.fn.stdpath("config") .. "/tests/editor.lua")
local remote, wait, feed = editor.remote, editor.wait, editor.feed
editor.run(function()
  remote([[
    _G.config_search_warnings = {}
    local notify = vim.notify
    vim.notify = function(message, level, opts)
      if level == vim.log.levels.WARN then
        table.insert(_G.config_search_warnings, message)
      end
      return notify(message, level, opts)
    end
  ]])
  feed(" sf")
  assert(
    remote(
      "return #require('snacks').picker.get() == 0 and _G.config_search_warnings[1]:find('File search requires', 1, true) ~= nil"
    )
  )
  feed(" sg")
  assert(
    remote(
      "return #require('snacks').picker.get() == 0 and _G.config_search_warnings[2]:find('Content search requires', 1, true) ~= nil"
    )
  )
  remote("vim.cmd.file('available.txt')")
  feed(" sb")
  wait("local p = require('snacks').picker.get()[1]; return p and p.list:count() > 0 and vim.fn.mode() == 'i'")
  feed("<CR>")
  wait("return #require('snacks').picker.get() == 0")
  feed("ihello<Esc>")
  assert(remote("return vim.api.nvim_get_current_line()") == "hello")
  remote([[
    local warnings = {}
    vim.health.start = function() end
    vim.health.info = function() end
    vim.health.ok = function() end
    vim.health.warn = function(message) warnings[#warnings + 1] = message end
    require("features.picker.tools").check()
    assert(vim.list_contains(warnings, "No file finder is available"))
    assert(vim.list_contains(warnings, "rg is unavailable; content search is disabled"))
  ]])
end, "Search missing tools checks: notices, health, buffer picker and native editing passed")
