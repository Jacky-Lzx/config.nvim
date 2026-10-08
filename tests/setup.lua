_G.config_test_errors = {}
local notify = vim.notify
vim.notify = function(message, level, options)
  if level == vim.log.levels.ERROR then
    _G.config_test_errors[#_G.config_test_errors + 1] = tostring(message)
  end
  return notify(message, level, options)
end
