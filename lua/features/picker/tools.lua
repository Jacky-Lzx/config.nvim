local M = {}

function M.status()
  local finder
  for _, name in ipairs({ "fd", "fdfind", "rg", "find" }) do
    if (name ~= "find" or vim.fn.has("win32") == 0) and vim.fn.executable(name) == 1 then
      finder = name
      break
    end
  end
  return { finder = finder, grep = vim.fn.executable("rg") == 1 }
end

function M.usable(source)
  if source ~= "files" and source ~= "grep" then
    return true
  end
  local status = M.status()
  if source == "files" and not status.finder then
    vim.notify("File search requires fd, fdfind, rg, or find", vim.log.levels.WARN)
    return false
  elseif source == "grep" and not status.grep then
    vim.notify("Content search requires rg (ripgrep)", vim.log.levels.WARN)
    return false
  end
  return true
end

function M.check()
  vim.health.start("Picker tools")
  local status = M.status()
  if status.finder then
    vim.health.ok("File finder: " .. vim.fn.exepath(status.finder))
    if status.finder == "find" then
      vim.health.info("The find fallback does not apply Git ignore rules; install fd or rg for that behavior")
    end
  else
    vim.health.warn("No file finder is available", { "Install fd or ripgrep" })
  end
  if status.grep then
    vim.health.ok("Content search: " .. vim.fn.exepath("rg"))
  else
    vim.health.warn("rg is unavailable; content search is disabled", { "Install ripgrep" })
  end
end

return M
