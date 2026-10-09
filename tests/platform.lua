local root = assert(vim.env.NVIM_CONFIG_ROOT, "NVIM_CONFIG_ROOT is required")
vim.opt.runtimepath:prepend(root)

local discoveries = 0
local sysname = "Darwin"
vim.uv.os_uname = function()
  discoveries = discoveries + 1
  return { sysname = sysname }
end
local definitions = require("config.platform")
assert(discoveries == 0, "Loading platform settings must not detect the environment")
local original = vim.deepcopy(definitions)

local paths, executables, jobs = {}, {}, {}
vim.fn.exepath = function(name)
  return paths[name] or ""
end
vim.fn.executable = function(path)
  return executables[path] and 1 or 0
end
local job_result = 1
vim.fn.jobstart = function(command, options)
  jobs[#jobs + 1] = { command = command, options = options }
  return job_result
end
for _, name in ipairs({
  "NVIM_SHELL",
  "SHELL",
  "NVIM_PYTHON3_HOST_PROG",
  "NVIM_DEBUGPY_PYTHON",
  "NVIM_OPEN_CMD",
  "NVIM_EXTERNAL_TERMINAL",
  "NVIM_SKIM_DISPLAYLINE",
  "NVIM_DEV_PLUGIN_ROOT",
  "VIRTUAL_ENV",
  "CONDA_PREFIX",
}) do
  vim.env[name] = nil
end

local function load_platform(name, settings)
  sysname = name
  package.loaded["utils.platform"] = nil
  package.loaded["config.platform"] = settings or definitions
  return require("utils.platform")
end

paths.open, paths["xdg-open"] = "/system/open", "/system/xdg-open"
local platform = load_platform("Darwin")
assert(platform.os == "macos" and platform.is("macos") and not platform.is("linux"))
local command = platform.opener()
assert(vim.deep_equal(command, { "/system/open" }))
command[1] = "changed"
assert(platform.open("/a file's name.pdf"))
assert(vim.deep_equal(jobs[1], {
  command = { "/system/open", "/a file's name.pdf" },
  options = { detach = true },
}))
assert(vim.deep_equal(platform.opener(), { "/system/open" }))
job_result = -1
local ok, err = platform.open("target")
assert(not ok and err == "Failed to start system opener")
job_result = 1

executables[definitions.macos.skim_displayline] = true
assert(platform.skim_displayline() == definitions.macos.skim_displayline)
platform = load_platform("Linux")
assert(platform.os == "linux" and vim.deep_equal(platform.opener(), { "/system/xdg-open" }))
assert(platform.skim_displayline() == nil, "macOS settings must not leak into Linux")
platform = load_platform("FreeBSD")
assert(platform.os == "other" and platform.opener() == nil)
local job_count = #jobs
ok, err = platform.open("target")
assert(not ok and err == "No system opener found; set NVIM_OPEN_CMD" and #jobs == job_count)

-- Per-platform lists replace defaults, and all other defaults remain available.
local settings = vim.deepcopy(definitions)
settings.linux.shell = { "bash" }
settings.linux.python = { "pypy3" }
settings.linux.opener = { "viewer", "--wait" }
settings.linux.python_host = "~/fixture/provider"
settings.linux.dev_plugin_root = "~/fixture/plugins"
paths.bash, paths.fish, paths.sh = "/system/bash", "/system/fish", "/system/sh"
paths.python, paths.viewer = "/system/python", "/system/viewer"
platform = load_platform("Linux", settings)
assert(platform.shell() == "/system/bash")
assert(platform.python() == "pypy3", "A default interpreter must not survive a list override")
assert(platform.open("target"))
assert(vim.deep_equal(jobs[#jobs].command, { "/system/viewer", "--wait", "target" }))
assert(vim.deep_equal(settings.linux.opener, { "viewer", "--wait" }))
local mason_tool = vim.fs.joinpath(vim.fn.stdpath("data"), settings.defaults.mason_bin, "tool")
executables[mason_tool] = true
assert(platform.executable("tool") == mason_tool)
paths.tool = "/system/tool"
assert(platform.executable("tool") == "/system/tool")
assert(platform.executable("missing") == nil)

-- Environment overrides remain live after module loading, with existing fallbacks.
executables["/override/shell"] = true
vim.env.NVIM_SHELL = "/override/shell"
assert(platform.shell() == "/override/shell")
vim.env.NVIM_SHELL = "/missing/shell"
assert(platform.shell() == "/system/bash")
paths.bash = nil
executables["/login/shell"] = true
vim.env.SHELL = "/login/shell"
assert(platform.shell() == "/login/shell")
vim.env.SHELL = nil
assert(platform.shell() == "/system/sh")

local provider = vim.fn.expand(settings.linux.python_host)
executables[provider], executables["/override/provider"] = true, true
assert(platform.python_host() == provider)
vim.env.NVIM_PYTHON3_HOST_PROG = "/override/provider"
assert(platform.python_host() == "/override/provider")
local debugpy = vim.fs.joinpath(vim.fn.stdpath("data"), settings.defaults.debugpy_python)
executables[debugpy], executables["/override/debugpy"] = true, true
assert(platform.debugpy_python() == debugpy)
vim.env.NVIM_DEBUGPY_PYTHON = "/override/debugpy"
assert(platform.debugpy_python() == "/override/debugpy")
paths.kitty = "/system/kitty"
assert(platform.external_terminal() == "/system/kitty")
executables["/override/terminal"] = true
vim.env.NVIM_EXTERNAL_TERMINAL = "/override/terminal"
assert(platform.external_terminal() == "/override/terminal")
executables["/override/displayline"] = true
vim.env.NVIM_SKIM_DISPLAYLINE = "/override/displayline"
assert(platform.skim_displayline() == "/override/displayline")
vim.env.NVIM_OPEN_CMD = "open --wait"
assert(vim.deep_equal(platform.opener(), { "/system/open", "--wait" }))
vim.env.NVIM_OPEN_CMD = "/override/open --wait"
executables["/override/open"] = true
assert(vim.deep_equal(platform.opener(), { "/override/open", "--wait" }))
vim.env.NVIM_OPEN_CMD = "missing"
assert(platform.opener() == nil, "An invalid explicit opener must not silently use the default")
assert(platform.dev_plugin_root() == vim.fn.expand(settings.linux.dev_plugin_root))
vim.env.NVIM_DEV_PLUGIN_ROOT = "/override/plugins"
assert(platform.dev_plugin_root() == "/override/plugins")
assert(vim.deep_equal(definitions, original), "Capability discovery must not mutate platform settings")
print("Platform configuration, OS selection, overrides and capability fallback checks passed")
