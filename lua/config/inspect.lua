local M = {}

local function integrations()
  local buf = vim.api.nvim_get_current_buf()
  local bootstrap, tex = package.loaded["image_tools.bootstrap"], package.loaded["tex-tools"]
  local preview = {
    bootstrap_loaded = bootstrap ~= nil,
    renderer_loaded = package.loaded["image_tools.runtime"] ~= nil,
    tex_loaded = tex ~= nil,
    owner = vim.b[buf].image_tools_preview_owner,
  }
  if bootstrap then
    preview.automatic = bootstrap.enabled()
  end
  if tex then
    preview.tex = vim.deepcopy(tex.formula_info())
  end
  local cmp, policy = package.loaded.completion_tools, package.loaded["integrations.completion"]
  local cycle = vim.b[buf].completion_tools_source_index or 1
  local completion = {
    loaded = cmp ~= nil,
    source_mode = cycle > 1 and "cycle" or vim.b[buf].completion_tools_sources and "manual" or "automatic",
    cycle_index = cycle,
  }
  if policy then
    local cursor = vim.api.nvim_win_get_cursor(0)
    local ctx = { bufnr = buf, row = cursor[1] - 1, col = cursor[2] }
    completion.current_sources =
      vim.deepcopy(require("integrations.completion.sources").active_sources(policy.source_config, ctx))
    local obsidian = package.loaded.obsidian_tools
    if obsidian and obsidian.workspace(vim.api.nvim_buf_get_name(buf)) then
      completion.current_sources[#completion.current_sources + 1] = "obsidian"
    end
  end
  if cmp then
    completion.last_request = vim.deepcopy(cmp.get_status())
  end
  local environments = package.loaded["workspace_tools.environments.python"]
  local python = { loaded = environments ~= nil }
  if environments then
    python = vim.deepcopy(environments.info({ buf = buf }))
    python.loaded = true
    if not python.python then
      python.python = require("utils.platform").python()
      python.source = "platform"
    end
  end
  return { preview = preview, completion = completion, python = python }
end

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
    project = require("config.project").info(),
    languages = {},
    tools = {},
    lsp = { enabled_servers = {} },
    plugins = { initialized = false, entries = {} },
    integrations = integrations(),
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
      name = tool.executable or tool.package,
      package = tool.package,
      feature = tool.feature,
      optional = tool.optional == true,
      path = path,
      available = path ~= nil,
    }
  end

  -- Inspect configuration state without requiring managed modules.
  local plugins = package.loaded["config.plugins"]
  local manager = plugins and plugins.manager
  if manager then
    result.plugins.initialized = true
    for _, plugin in ipairs(manager:status()) do
      local detail = manager:explain(plugin.id)
      result.plugins.entries[#result.plugins.entries + 1] = {
        name = plugin.id,
        directory = plugin.dir,
        source = plugin.managed and "git" or "local",
        development = not plugin.managed
          and plugin.dir:sub(1, #result.paths.dev_plugins + 1) == result.paths.dev_plugins .. "/",
        url = detail.source,
        loaded = plugin.state.phase == "ready",
        phase = plugin.state.phase,
        reason = plugin.state.reason,
        trigger = vim.deepcopy(plugin.state.trigger),
        error = plugin.state.error,
      }
    end
    table.sort(result.plugins.entries, function(a, b)
      return a.name < b.name
    end)
  end
  return result
end

return M
