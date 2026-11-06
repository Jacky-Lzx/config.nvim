local M = {}
function M.setup()
  local directory = vim.env.NVIM_PLUGIN_TOOLS_PATH
    or (require("utils.platform").dev_plugin_root() .. "/plugin-tools.nvim")
  assert(vim.uv.fs_stat(directory .. "/lua/plugin_tools/init.lua"), "plugin-tools.nvim is missing: " .. directory)
  vim.opt.runtimepath:prepend(directory)
  M.manager = require("plugin_tools").setup({
    specs = require("config.specs").build(),
    -- GitHub owner/repo sources share this protocol; SSH: "git@github.com:%s.git".
    url_format = "https://github.com/%s.git",
    dev = { path = require("utils.platform").dev_plugin_root(), fallback = true },
    lockfile = require("config.lockfile").resolve(),
    root = vim.env.NVIM_PLUGIN_ROOT or (vim.fn.stdpath("data") .. "/plugin-tools"),
  })
  vim.keymap.set("n", "<leader>L", "<cmd>PluginTools<cr>", { desc = "[Plugins] Open plugin status" })
  vim.api.nvim_create_user_command("ConfigToolsInstall", function()
    require("integrations.toolchain").install()
  end, { desc = "Install tools and parsers for enabled language profiles", force = true })
  local function ready()
    vim.schedule(function()
      vim.g.config_ready = true
      vim.api.nvim_exec_autocmds("User", { pattern = "ConfigReady", modeline = false })
    end)
  end
  if vim.v.vim_did_enter == 1 then
    ready()
  else
    vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = ready })
  end
end
function M.nodes()
  return M.manager and M.manager.graph.nodes or {}
end
function M.options(id)
  return vim.deepcopy(assert(M.nodes()[id], "Unknown configured plugin: " .. id).opts)
end
function M.initialized(id)
  return M.manager ~= nil and M.manager.states[id] ~= nil and M.manager.states[id].phase == "ready"
end
return M
