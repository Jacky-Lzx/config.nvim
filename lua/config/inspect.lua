local M = {}

function M.snapshot()
  local context = require("config.context").current()
  local platform = require("utils.platform")
  local version = vim.version()
  local result = {
    version = ("%d.%d.%d"):format(version.major, version.minor, version.patch),
    platform = platform.os,
    paths = {
      checkout = require("utils.paths").root,
      config = vim.fn.stdpath("config"),
      data = vim.fn.stdpath("data"),
      state = vim.fn.stdpath("state"),
      cache = vim.fn.stdpath("cache"),
      dev_plugins = platform.dev_plugin_root(),
    },
    selection = vim.deepcopy(context.selection),
    languages = {},
    tools = {},
    lsp = { enabled_servers = {} },
    plugins = { initialized = false, entries = {} },
  }
  for _, field in ipairs({ "names", "servers", "parsers", "formatters", "linters" }) do
    result.languages[field] = vim.deepcopy(context.languages[field])
  end
  local lsp = package.loaded["vim.lsp"]
  for _, server in ipairs(context.languages.servers) do
    if lsp and lsp.is_enabled(server) then
      result.lsp.enabled_servers[#result.lsp.enabled_servers + 1] = server
    end
  end
  for _, tool in ipairs(context.languages.tools) do
    local path
    if tool.resolve then
      path = tool.resolve()
    else
      path = platform.executable(tool.executable)
    end
    result.tools[#result.tools + 1] = {
      name = tool.executable or tool.mason,
      mason = tool.mason,
      feature = tool.feature,
      path = path,
      available = path ~= nil,
    }
  end

  -- Inspect resolved specs without requiring lazy.nvim or loading any plugin.
  local lazy = package.loaded["lazy.core.config"]
  if lazy and lazy.plugins then
    result.plugins.initialized = true
    for _, name in ipairs(vim.fn.sort(vim.tbl_keys(lazy.plugins))) do
      local plugin = lazy.plugins[name]
      local state = plugin._ or {}
      result.plugins.entries[#result.plugins.entries + 1] = {
        name = name,
        directory = plugin.dir,
        source = state.is_local and "local" or "git",
        development = plugin.dev == true,
        url = plugin.url,
        loaded = not not state.loaded,
      }
    end
  end
  return result
end

return M
