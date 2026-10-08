local M = {}

local platform = require("config.platform")
local languages = require("languages")

local function check_executable(name, required)
  local path = platform.executable(name)
  if path then
    vim.health.ok(('%s: "%s"'):format(name, path))
  elseif required then
    vim.health.error(("%s is not executable"):format(name))
  else
    vim.health.warn(("%s is not executable; related features will be unavailable"):format(name))
  end
end

function M.check()
  vim.health.start("Neovim config")
  vim.health.info("Platform: " .. platform.os)
  vim.health.info("Enabled profiles: " .. table.concat(require("config.context").current().selection.profiles, ", "))

  check_executable("git", true)

  local shell = platform.shell()
  if shell then
    vim.health.ok('Shell: "' .. shell .. '"')
  else
    vim.health.error("No usable shell found; set NVIM_SHELL")
  end

  local opener = platform.opener()
  if opener then
    vim.health.ok("System opener: " .. table.concat(opener, " "))
  else
    vim.health.warn("No system opener found; set NVIM_OPEN_CMD")
  end

  local python = platform.python_host()
  if python then
    vim.health.ok('Python provider: "' .. python .. '"')
  else
    vim.health.warn("No explicit Python provider; set NVIM_PYTHON3_HOST_PROG if auto-discovery fails")
  end

  vim.health.start("Optional integrations")
  for _, executable in ipairs({ "delta", "lazygit", "yazi", "kitty", "magick" }) do
    check_executable(executable, false)
  end
  if platform.is("macos") then
    if platform.skim_displayline() then
      vim.health.ok("Skim forward search is available")
    else
      vim.health.warn("Skim is unavailable; LaTeX preview will use zathura when available")
    end
  else
    check_executable("zathura", false)
  end

  require("config.pairing").check()

  vim.health.start("Enabled language tools")
  local seen = {}
  for _, tool in ipairs(languages.current().tools) do
    local name = tool.executable or tool.mason
    if not seen[name] then
      seen[name] = true
      if tool.resolve then
        local path = tool.resolve()
        if path then
          vim.health.ok(('%s: "%s"'):format(name, path))
        else
          vim.health.warn(name .. " is unavailable; run :ConfigToolsInstall or configure its system path")
        end
      else
        check_executable(name, false)
      end
    end
  end
end

return M
