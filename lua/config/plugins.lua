local M = {}
local started = false
local active = {}
local modules = {
  theme = "features.theme",
  input = "features.input",
  picker = "features.picker",
  treesitter = "features.treesitter",
  textobjects = "features.textobjects",
  git = "features.git",
}
local order = { "theme", "input", "picker", "treesitter", "textobjects", "git" }

local function root()
  return vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
end

local function lockfile()
  return vim.fs.joinpath(vim.fn.stdpath("config"), "lazy-lock.json")
end

function M.status()
  local settings = require("config.settings").current()
  local manager = vim.fn.filereadable(vim.fs.joinpath(root(), "lazy.nvim", "lua/lazy/init.lua")) == 1
  local enabled, missing, features = false, {}, {}
  for _, name in ipairs(order) do
    local selected = settings.features[name]
    local absent = {}
    if selected then
      enabled = true
      for _, plugin in ipairs(require(modules[name]).requirements()) do
        if vim.fn.filereadable(vim.fs.joinpath(root(), plugin[1], plugin[2])) == 0 then
          absent[#absent + 1] = plugin[1]
          missing[#missing + 1] = plugin[1]
        end
      end
    end
    features[name] = {
      enabled = selected,
      available = selected and manager and #absent == 0,
      active = active[name] == true,
      missing = absent,
    }
  end
  if enabled and not manager then
    table.insert(missing, 1, "lazy.nvim")
  end
  return { enabled = enabled, started = started, root = root(), missing = missing, features = features }
end

local function setup_manager(install)
  if started then
    return
  end
  local status, specs = M.status(), {}
  for _, name in ipairs(order) do
    local feature = status.features[name]
    if install and feature.enabled or feature.available then
      vim.list_extend(specs, require(modules[name]).specs())
      active[name] = true
    end
  end
  if #specs == 0 then
    return
  end
  vim.opt.runtimepath:prepend(vim.fs.joinpath(root(), "lazy.nvim"))
  require("lazy").setup({
    spec = specs,
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
  if not vim.g.config_plugin_install then
    setup_manager(false)
  end
end

local function git(args)
  local result = vim.system(vim.list_extend({ "git" }, args), { text = true }):wait()
  assert(result.code == 0, "Plugin installation failed:\n" .. (result.stderr or result.stdout or ""))
end

function M.install()
  assert(M.status().enabled, "Enable a plugin feature before installing plugins")
  if not vim.g.config_plugin_install then
    local result = vim
      .system({
        vim.v.progpath,
        "--headless",
        "-i",
        "NONE",
        "--cmd",
        "let g:config_plugin_install=1",
        "-c",
        "lua local ok, err = pcall(require('config.plugins').install); if not ok then print(err); vim.cmd.cquit(1) end",
        "-c",
        "qa!",
      }, { text = true })
      :wait()
    assert(result.code == 0, "Plugin installation failed:\n" .. (result.stderr or "") .. (result.stdout or ""))
    vim.notify("Plugins installed. Restart Neovim to activate the complete configuration.", vim.log.levels.INFO)
    return
  end
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
  setup_manager(true)
  require("lazy").install({ wait = true, show = false, lockfile = true })
  local missing = M.status().missing
  assert(#missing == 0, "Plugins are still missing: " .. table.concat(missing, ", "))
end

return M
