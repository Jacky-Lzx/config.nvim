_G.config_test_errors = {}
if vim.env.NVIM_TEST_TS_TOOLS == "missing" then
  local executable = vim.fn.executable
  vim.fn.executable = function(name)
    return name == "tree-sitter" and 0 or executable(name)
  end
end
if vim.env.NVIM_TEST_PICKER_TOOLS then
  local executable = vim.fn.executable
  local mode = vim.env.NVIM_TEST_PICKER_TOOLS
  vim.fn.executable = function(name)
    local masked = mode == "rg-only" and (name == "fd" or name == "fdfind")
      or mode == "missing" and vim.list_contains({ "fd", "fdfind", "rg", "find" }, name)
    return masked and 0 or executable(name)
  end
end
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
