local M = {
  source = "Jacky-Lzx/plugin-tools.nvim",
  commit = "4d91ef702d2f770dc32236f928ca8f17448a2691",
}

function M.installed()
  return vim.fs.joinpath(vim.fn.stdpath("data"), "plugin-tools-manager", M.commit)
end

function M.directory()
  if vim.env.NVIM_PLUGIN_TOOLS_PATH and vim.env.NVIM_PLUGIN_TOOLS_PATH ~= "" then
    return vim.fn.expand(vim.env.NVIM_PLUGIN_TOOLS_PATH)
  end
  local development = require("utils.platform").dev_plugin_root() .. "/plugin-tools.nvim"
  return vim.uv.fs_stat(development .. "/lua/plugin_tools/init.lua") and development or M.installed()
end

function M.mount()
  local directory = M.directory()
  assert(
    vim.uv.fs_stat(directory .. "/lua/plugin_tools/init.lua"),
    "plugin-tools.nvim is missing; run nvim --headless -u NONE -i NONE -l "
      .. require("utils.paths").config("scripts/install-plugins.lua")
  )
  vim.opt.runtimepath:prepend(directory)
  return directory
end

-- Explicit installation only. Startup never calls Git or downloads a manager.
function M.ensure(url_format)
  local directory = M.directory()
  if vim.uv.fs_stat(directory .. "/lua/plugin_tools/init.lua") then
    return M.mount()
  end
  assert(
    not vim.env.NVIM_PLUGIN_TOOLS_PATH or vim.env.NVIM_PLUGIN_TOOLS_PATH == "",
    "Explicit NVIM_PLUGIN_TOOLS_PATH is missing: " .. directory
  )
  assert(not vim.uv.fs_lstat(directory), "Refusing to replace an incomplete manager directory: " .. directory)
  local parent = vim.fs.dirname(directory)
  vim.fn.mkdir(parent, "p")
  local staging = assert(vim.uv.fs_mkdtemp(parent .. "/.install-XXXXXX"))
  local function command(args)
    local result = vim.system(args, { text = true, env = { GIT_TERMINAL_PROMPT = "0" } }):wait(120000)
    assert(result.code == 0, result.stderr)
    return vim.trim(result.stdout)
  end
  local ok, err = xpcall(function()
    command({ "git", "init", "--quiet", staging })
    command({ "git", "-C", staging, "remote", "add", "origin", url_format:format(M.source) })
    command({ "git", "-C", staging, "fetch", "--quiet", "--depth=1", "origin", M.commit })
    command({ "git", "-C", staging, "checkout", "--quiet", "--detach", "FETCH_HEAD" })
    assert(command({ "git", "-C", staging, "rev-parse", "HEAD" }) == M.commit, "Manager revision mismatch")
    assert(vim.uv.fs_stat(staging .. "/lua/plugin_tools/init.lua"), "Invalid manager checkout")
    assert(vim.uv.fs_rename(staging, directory))
  end, debug.traceback)
  if vim.uv.fs_lstat(staging) then
    vim.fn.delete(staging, "rf")
  end
  assert(ok, err)
  return M.mount()
end

return M
