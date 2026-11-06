-- Run the shared nested-picker scenarios with the actual configured bindings.
local timer = vim.uv.new_timer()
timer:start(
  20,
  20,
  vim.schedule_wrap(function()
    if not vim.g.config_ready then
      return
    end
    timer:stop()
    timer:close()
    vim.env.KEYMAP_TOOLS_CONFIGURED = "1"
    vim.env.KEYMAP_TOOLS_TEST_DIR = vim.env.NVIM_TEST_TMP
    vim.env.KEYMAP_TOOLS_RESULT = vim.env.NVIM_STARTUP_RESULT
    dofile(require("utils.platform").dev_plugin_root() .. "/keymap-tools.nvim/tests/nested_picker_tui.lua")
  end)
)
