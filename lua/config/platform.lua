local M = {}

local sysname = vim.uv.os_uname().sysname
M.os = sysname == "Darwin" and "macos" or sysname == "Linux" and "linux" or "other"

function M.is(name)
  return M.os == name
end

function M.executable(name)
  local path = vim.fn.exepath(name)
  if path ~= "" then
    return path
  end

  local mason_path = vim.fn.stdpath("data") .. "/mason/bin/" .. name
  return vim.fn.executable(mason_path) == 1 and mason_path or nil
end

local function executable_path(path)
  path = path and vim.fn.expand(path) or nil
  return path and path ~= "" and vim.fn.executable(path) == 1 and path or nil
end

function M.shell()
  return executable_path(vim.env.NVIM_SHELL)
    or M.executable("fish")
    or executable_path(vim.env.SHELL)
    or M.executable("sh")
end

function M.python_host()
  return executable_path(vim.env.NVIM_PYTHON3_HOST_PROG) or executable_path(vim.fn.expand("~/.uv/neovim/bin/python3"))
end

function M.python()
  return M.python_host() or M.executable("python3") or M.executable("python") or "python3"
end

function M.debugpy_python()
  return executable_path(vim.env.NVIM_DEBUGPY_PYTHON)
    or executable_path(vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python")
end

function M.opener()
  if vim.env.NVIM_OPEN_CMD and vim.env.NVIM_OPEN_CMD ~= "" then
    local command = vim.split(vim.env.NVIM_OPEN_CMD, "%s+", { trimempty = true })
    local executable = command[1] and (M.executable(command[1]) or executable_path(command[1])) or nil
    if executable then
      command[1] = executable
      return command
    end
    return nil
  end
  local name = M.is("macos") and "open" or M.is("linux") and "xdg-open" or nil
  local executable = name and M.executable(name) or nil
  return executable and { executable } or nil
end

function M.open(target)
  local command = M.opener()
  if not command then
    return false, "No system opener found; set NVIM_OPEN_CMD"
  end

  command = vim.list_extend(vim.deepcopy(command), { target })
  if vim.fn.jobstart(command, { detach = true }) <= 0 then
    return false, "Failed to start system opener"
  end
  return true
end

function M.external_terminal()
  return executable_path(vim.env.NVIM_EXTERNAL_TERMINAL) or M.executable("kitty")
end

function M.skim_displayline()
  return executable_path(vim.env.NVIM_SKIM_DISPLAYLINE)
    or (M.is("macos") and executable_path("/Applications/Skim.app/Contents/SharedSupport/displayline") or nil)
end

function M.dev_plugin_root()
  return vim.fn.expand(vim.env.NVIM_DEV_PLUGIN_ROOT or "~/Documents/Github/nvim_plugins")
end

function M.obsidian_workspace()
  return vim.fn.expand(vim.env.NVIM_OBSIDIAN_WORKSPACE or "~/Research/Obsidian_Workspace")
end

return M
