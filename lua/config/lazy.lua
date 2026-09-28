-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  if vim.env.NVIM_SMOKE_TEST == "1" then
    error("lazy.nvim is missing; smoke tests never install dependencies")
  end
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

local spec = {
  { import = "plugins.core" },
  { import = "plugins.extra" },
}
for _, language in ipairs(require("config.languages").enabled_languages()) do
  spec[#spec + 1] = { import = "plugins.languages." .. language }
end

local opts = {
  spec = spec,
  install = {
    -- install missing plugins on startup. This doesn't increase startup time.
    missing = vim.env.NVIM_SMOKE_TEST ~= "1",
    -- try to load one of these colorschemes when starting an installation during startup
    colorscheme = { "catppuccin" },
  },
  -- automatically check for plugin updates
  -- checker = { enabled = true },
  git = {
    timeout = 120,
    -- url_format = "git@github.com:%s.git",
  },
  ui = {
    -- The border to use for the UI window. Accepts same border values as |nvim_open_win()|.
    border = "rounded",
    icons = {
      cmd = "",
      config = "",
      event = "󱐋",
      ft = "",
      init = "",
      import = "",
      keys = "",
      lazy = "󰒲 ",
      loaded = "●",
      not_loaded = "○",
      plugin = "",
      runtime = "",
      source = "",
      start = "",
      task = "✔",
      list = {
        "●",
        "➜",
        "★",
        "‒",
      },
    },
  },
  performance = {
    rtp = {
      disabled_plugins = {
        -- "matchparen",
        "gzip",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "zipPlugin",
        "tutor",
      },
    },
  },
  dev = {
    -- Directory where you store your local plugin projects. If a function is used,
    -- the plugin directory (e.g. `~/projects/plugin-name`) must be returned.
    ---@type string | fun(plugin: LazyPlugin): string
    path = require("config.platform").dev_plugin_root(),
    fallback = true, -- Fallback to git when local plugin doesn't exist
  },
}

require("lazy").setup(opts)

vim.keymap.set("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "[Lazy] Open Lazy.nvim" })

vim.api.nvim_create_user_command("ConfigToolsInstall", function()
  vim.cmd("TSInstallConfigured")
  vim.cmd("MasonToolsInstall")
end, { desc = "Install tools and parsers for enabled language profiles", force = true })
