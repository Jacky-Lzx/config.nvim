local M = {}

local platform = require("utils.platform")

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
  local info = require("config.inspect").snapshot()
  vim.health.start("Neovim config")
  vim.health.info("Platform: " .. info.platform)
  vim.health.info("Configuration checkout: " .. info.paths.checkout)
  vim.health.info("Enabled profiles: " .. table.concat(info.selection.profiles, ", "))
  local features = {}
  for _, name in ipairs(require("config.features").names) do
    features[#features + 1] = name .. "=" .. tostring(info.selection.features[name])
  end
  vim.health.info("Workflows: " .. table.concat(features, ", "))
  vim.health.info("Selected LSP servers: " .. table.concat(info.languages.servers, ", "))
  vim.health.info("Enabled LSP servers: " .. table.concat(info.lsp.enabled_servers, ", "))
  vim.health.info("Run :ConfigInfo for resolved plugin directories and loading state")

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

  vim.health.start("Enabled language tools")
  local seen = {}
  for _, tool in ipairs(info.tools) do
    local name = tool.name
    if not seen[name] then
      seen[name] = true
      if tool.available then
        vim.health.ok(('%s: "%s"'):format(name, tool.path))
      else
        vim.health.warn(name .. " is unavailable; run :ConfigToolsInstall or configure its system path")
      end
    end
  end
end

return M
