local api = vim.api
local temp = assert(vim.uv.fs_realpath(vim.env.NVIM_TEST_TMP))

local function check()
  local plugins = require("lazy.core.config").plugins
  for _, name in ipairs({ "vim-startuptime", "vim-suda", "lazydev.nvim" }) do
    assert(not plugins[name], "Replaced utility is still configured: " .. name)
  end
  assert(not package.loaded["debug_tools.startuptime"] and not package.loaded["file_tools.privileged"])
  assert(not package.loaded["lsp-tools.languages.lua.resolve"])
  assert(not plugins["file-tools.nvim"]._.loaded, "Sudo commands must remain lazy")
  for _, command in ipairs({ "StartupTime", "SudaRead", "SudaWrite", "FileToolsRead", "FileToolsWrite" }) do
    assert(vim.fn.exists(":" .. command) == 2, command)
  end

  vim.cmd("StartupTime")
  local startup = require("debug_tools.startuptime")
  assert(
    vim.wait(20000, function()
      return startup.last ~= nil
    end, 20),
    "Configured startup measurement did not complete"
  )
  assert(startup.last.tries == 10 and startup.last.mean > 0)
  assert(vim.bo.filetype == "debug-tools-startuptime")
  assert(api.nvim_buf_get_lines(0, 0, 1, false)[1]:find("10 runs", 1, true))
  api.nvim_feedkeys("q", "xt", false)
  assert(vim.bo.filetype ~= "debug-tools-startuptime")

  -- A fake sudo runs the real transfer against private fixtures only.
  local bin = temp .. "/native-utilities-bin"
  vim.fn.mkdir(bin, "p")
  vim.fn.writefile({
    "#!/bin/sh",
    'if [ "$1" = "-n" ] && [ "$2" = "-v" ]; then exit 0; fi',
    'if [ "$1" = "-n" ]; then shift; fi',
    'if [ "$1" = "--" ]; then shift; fi',
    'exec "$@"',
  }, bin .. "/sudo")
  assert(vim.uv.fs_chmod(bin .. "/sudo", 448))
  local original_path = vim.env.PATH
  vim.env.PATH = bin .. ":" .. original_path
  local saved = temp .. "/literal $() 中.txt"
  vim.cmd("enew!")
  api.nvim_buf_set_name(0, saved)
  api.nvim_buf_set_lines(0, 0, -1, false, { "saved through SudaWrite" })
  vim.bo.fileformat = "dos"
  vim.cmd("SudaWrite")
  assert(
    vim.wait(3000, function()
      return not vim.bo.modified
    end, 10),
    "SudaWrite did not save"
  )
  assert(vim.fn.readfile(saved, "b")[1] == "saved through SudaWrite\r")
  api.nvim_buf_set_lines(0, 0, -1, false, { "discard this" })
  vim.cmd("SudaRead!")
  assert(
    vim.wait(3000, function()
      return not vim.bo.modified
    end, 10),
    "SudaRead did not finish"
  )
  assert(api.nvim_get_current_line() == "saved through SudaWrite" and vim.bo.fileformat == "dos")
  vim.env.PATH = original_path

  -- Restore actual server startup; setup.lua otherwise records starts only.
  vim.lsp.start = _G.config_test_real_lsp_start
  local project = temp .. "/native-utilities-lua"
  vim.fn.mkdir(project, "p")
  vim.fn.writefile({ '{ "completion.autoRequire": false }' }, project .. "/.luarc.json")
  vim.fn.writefile({
    'local debug_tools = require("debug_tools")',
    "debug_tools.inspect({ answer = 42 })",
    "local uv = vim.uv",
    "print(uv)",
  }, project .. "/main.lua")
  vim.cmd.edit(project .. "/main.lua")
  local buf = api.nvim_get_current_buf()
  local client
  local plugin_root = assert(vim.uv.fs_realpath(require("utils.platform").dev_plugin_root()))
  assert(
    vim.wait(10000, function()
      client = vim.lsp.get_clients({ bufnr = buf, name = "lua_ls" })[1]
      local library = client and vim.tbl_get(client.settings, "Lua", "workspace", "library") or {}
      return vim.tbl_contains(library, plugin_root .. "/debug-tools.nvim/lua")
        and vim.tbl_contains(library, "${3rd}/luv/library")
    end, 20),
    "Configured LuaLS did not receive conditional libraries"
  )
  local target = vim.uri_from_fname(plugin_root .. "/debug-tools.nvim/lua/debug_tools/init.lua")
  assert(
    vim.wait(10000, function()
      local response = client:request_sync("textDocument/definition", {
        textDocument = { uri = vim.uri_from_bufnr(buf) },
        position = { line = 1, character = 15 },
      }, 2000, buf)
      for _, location in ipairs(response and response.result or {}) do
        if (location.uri or location.targetUri) == target then
          return true
        end
      end
      return false
    end, 50),
    "Configured LuaLS could not resolve debug-tools source"
  )
  assert(not package.loaded.lazydev)
end

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    vim.defer_fn(function()
      local ok, err = xpcall(check, debug.traceback)
      for _, client in ipairs(vim.lsp.get_clients()) do
        client:stop(true)
      end
      vim.fn.writefile({
        ok and "Configured PTY: cold commands, ten native startup runs, sudo aliases and actual LuaLS libraries passed"
          or err,
      }, vim.env.NVIM_LAZY_RESULT)
      vim.cmd(ok and "qa!" or "cquit 1")
    end, 50)
  end,
})
