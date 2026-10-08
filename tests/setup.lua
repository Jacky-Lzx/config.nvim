_G.config_test_errors = {}
if vim.env.NVIM_TEST_LSP_MODE == "missing" then
  local executable = vim.fn.executable
  vim.fn.executable = function(name)
    return name == "lua-language-server" and 0 or executable(name)
  end
end
local notify = vim.notify
vim.notify = function(message, level, options)
  if level == vim.log.levels.ERROR then
    _G.config_test_errors[#_G.config_test_errors + 1] = tostring(message)
  end
  return notify(message, level, options)
end
