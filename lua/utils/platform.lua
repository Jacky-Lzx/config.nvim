local M = {}

local definitions = require("config.platform")
local sysname = vim.uv.os_uname().sysname
M.os = "other"
for name, definition in pairs(definitions) do
  if name ~= "defaults" and definition.sysname == sysname then
    M.os = name
    break
  end
end
local config = vim.tbl_extend("force", vim.deepcopy(definitions.defaults), vim.deepcopy(definitions[M.os]))

function M.is(name)
  return M.os == name
end

function M.executable(name)
  local path = vim.fn.exepath(name)
  if path ~= "" then
    return path
  end

  local mason_path = vim.fs.joinpath(vim.fn.stdpath("data"), config.mason_bin, name)
  return vim.fn.executable(mason_path) == 1 and mason_path or nil
end

local function executable_path(path)
  path = path and vim.fn.expand(path) or nil
  return path and path ~= "" and vim.fn.executable(path) == 1 and path or nil
end

local function configured_executable(name)
  return name and (M.executable(name) or executable_path(name)) or nil
end

local function first_executable(names)
  for _, name in ipairs(names) do
    local path = configured_executable(name)
    if path then
      return path
    end
  end
end

function M.shell()
  return executable_path(vim.env.NVIM_SHELL)
    or first_executable(config.shell)
    or executable_path(vim.env.SHELL)
    or configured_executable(config.shell_fallback)
end

function M.python_host()
  return executable_path(vim.env.NVIM_PYTHON3_HOST_PROG) or executable_path(config.python_host)
end

function M.python()
  local selector = package.loaded["venv-selector"]
  local selected = selector and executable_path(selector.python())
  if selected then
    return selected
  end
  for _, name in ipairs({ "VIRTUAL_ENV", "CONDA_PREFIX" }) do
    local env = vim.env[name]
    local python = env and env ~= "" and executable_path(vim.fs.joinpath(env, config.virtualenv_python))
    if python then
      return python
    end
  end
  return first_executable(config.python) or config.python[1]
end

function M.debugpy_python()
  return executable_path(vim.env.NVIM_DEBUGPY_PYTHON)
    or (
      config.debugpy_python and executable_path(vim.fs.joinpath(vim.fn.stdpath("data"), config.debugpy_python)) or nil
    )
end

function M.opener()
  local command = config.opener
  if vim.env.NVIM_OPEN_CMD and vim.env.NVIM_OPEN_CMD ~= "" then
    command = vim.split(vim.env.NVIM_OPEN_CMD, "%s+", { trimempty = true })
  end
  command = command and vim.deepcopy(command) or nil
  local executable = command and configured_executable(command[1]) or nil
  if executable then
    command[1] = executable
    return command
  end
end

function M.open(target)
  local command = M.opener()
  if not command then
    return false, "No system opener found; set NVIM_OPEN_CMD"
  end

  command = vim.list_extend(command, { target })
  if vim.fn.jobstart(command, { detach = true }) <= 0 then
    return false, "Failed to start system opener"
  end
  return true
end

function M.external_terminal()
  return executable_path(vim.env.NVIM_EXTERNAL_TERMINAL) or configured_executable(config.external_terminal)
end

function M.skim_displayline()
  return executable_path(vim.env.NVIM_SKIM_DISPLAYLINE) or executable_path(config.skim_displayline)
end

function M.dev_plugin_root()
  return vim.fn.expand(vim.env.NVIM_DEV_PLUGIN_ROOT or config.dev_plugin_root)
end

return M
