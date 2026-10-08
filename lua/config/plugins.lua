local M = {}
local started = false

local function root()
  return vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
end

local function lockfile()
  return vim.fs.joinpath(vim.fn.stdpath("config"), "lazy-lock.json")
end

function M.status()
  local enabled = require("config.settings").current().features.input
  local missing = {}
  if enabled then
    local requirements = { { "lazy.nvim", "lua/lazy/init.lua" } }
    vim.list_extend(requirements, require("features.input").requirements())
    for _, plugin in ipairs(requirements) do
      if vim.fn.filereadable(vim.fs.joinpath(root(), plugin[1], plugin[2])) == 0 then
        missing[#missing + 1] = plugin[1]
      end
    end
  end
  return { enabled = enabled, started = started, root = root(), missing = missing }
end

local function setup_manager()
  if started then
    return
  end
  vim.opt.runtimepath:prepend(vim.fs.joinpath(root(), "lazy.nvim"))
  require("lazy").setup({
    spec = require("features.input").specs(),
    root = root(),
    lockfile = lockfile(),
    local_spec = false,
    install = { missing = false },
    checker = { enabled = false },
    change_detection = { enabled = false },
    pkg = { enabled = false },
    rocks = { enabled = false },
    ui = { border = "rounded" },
  })
  started = true
end

function M.setup()
  local status = M.status()
  if status.enabled and #status.missing == 0 then
    setup_manager()
  end
end

local function git(args)
  local result = vim.system(vim.list_extend({ "git" }, args), { text = true }):wait()
  assert(result.code == 0, "Plugin installation failed:\n" .. (result.stderr or result.stdout or ""))
end

function M.install()
  assert(require("config.settings").current().features.input, "Enable a plugin feature before installing plugins")
  assert(vim.fn.executable("git") == 1, "Git is required to install plugins")
  local path = vim.fs.joinpath(root(), "lazy.nvim")
  if vim.fn.filereadable(vim.fs.joinpath(path, "lua/lazy/init.lua")) == 0 then
    local lock = vim.json.decode(table.concat(vim.fn.readfile(lockfile()), "\n"))
    local commit = assert(lock["lazy.nvim"], "The lockfile needs a lazy.nvim entry").commit
    assert(type(commit) == "string" and commit:match("^%x+$") and #commit == 40, "Invalid lazy.nvim lock revision")
    vim.fn.mkdir(root(), "p")
    if vim.fn.isdirectory(path) == 0 then
      git({ "clone", "--filter=blob:none", "--no-checkout", "https://github.com/folke/lazy.nvim.git", path })
    end
    git({ "-C", path, "checkout", "--detach", commit })
  end
  assert(vim.fn.filereadable(vim.fs.joinpath(path, "lua/lazy/init.lua")) == 1, "The lazy.nvim checkout is incomplete")
  setup_manager()
  require("lazy").install({ wait = true, show = false, lockfile = true })
  local missing = M.status().missing
  assert(#missing == 0, "Plugins are still missing: " .. table.concat(missing, ", "))
  vim.notify("Plugins installed. Restart Neovim to activate the complete configuration.", vim.log.levels.INFO)
end

return M
