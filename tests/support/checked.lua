-- UI providers can capture Neovim's default error display; keep failures visible in CI.
local ok, err = xpcall(function()
  dofile(assert(vim.env.NVIM_CONFIG_ROOT) .. "/tests/support/full_plugins.lua")
  if vim.env.NVIM_TEST_ISOLATE_PLUGINS == "1" then
    for _, lib in ipairs({
      { "keymap-tools.nvim", "keymap_tools.bindings" },
      { "bigfile-tools.nvim", "bigfile_tools.init" },
      { "completion-tools.nvim", "completion_tools.source_selection" },
    }) do
      local id, module = lib[1], lib[2]
      local key = module == "bigfile_tools.init" and "bigfile_tools" or module
      package.preload[key] = function()
        return assert(
          loadfile(
            assert(vim.env.NVIM_TEST_PLUGIN_FIXTURES) .. "/" .. id .. "/lua/" .. module:gsub("%.", "/") .. ".lua"
          )
        )()
      end
    end
  end
  dofile(assert(arg[1], "Expected a test script"))
end, debug.traceback)
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
end
