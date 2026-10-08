local M = {}

-- Resolution is pure with respect to editor state: definitions describe capabilities;
-- plugin hooks are executed later by lazy.nvim. Explicit selections make tests independent
-- of the user's personal defaults.
function M.resolve(selection)
  selection = selection or require("config.selection")
  local profiles = require("config.profiles")
  local result = {
    names = {},
    servers = {},
    parsers = {},
    tools = {},
    plugins = {},
    formatters = {},
    formatter_options = {},
    linters = {},
    linter_options = {},
  }
  local seen = { names = {}, servers = {}, parsers = {}, tools = {} }
  local function append_unique(field, value, key)
    key = key or value
    if not seen[field][key] then
      seen[field][key] = true
      result[field][#result[field] + 1] = vim.deepcopy(value)
    end
  end
  for _, profile in ipairs(selection.profiles) do
    assert(profiles[profile], "Unknown language profile: " .. profile)
    for _, name in ipairs(profiles[profile]) do
      if not seen.names[name] then
        assert(name:match("^[a-z][a-z0-9_]*$"), "Invalid language name: " .. name)
        local ok, definition = pcall(require, "languages." .. name)
        assert(ok, "Cannot load language " .. name .. ": " .. tostring(definition))
        append_unique("names", name)
        for _, field in ipairs({ "servers", "parsers" }) do
          for _, value in ipairs(definition[field] or {}) do
            append_unique(field, value)
          end
        end
        for _, tool in ipairs(definition.tools or {}) do
          assert(tool.executable or tool.resolve, "Tool needs an executable or resolver: " .. name)
          if not tool.feature or selection.features[tool.feature] then
            append_unique("tools", tool, tool.mason and ("mason:" .. tool.mason) or ("system:" .. tool.executable))
          end
        end
        for _, field in ipairs({ "formatters", "formatter_options", "linters", "linter_options" }) do
          for key, value in pairs(definition[field] or {}) do
            local previous = result[field][key]
            assert(
              previous == nil or vim.deep_equal(previous, value),
              ("Conflicting %s.%s in language %s"):format(field, key, name)
            )
            result[field][key] = vim.deepcopy(value)
          end
        end
        vim.list_extend(result.plugins, vim.deepcopy(definition.plugins or {}))
      end
    end
  end
  return result
end

function M.current()
  return require("config.context").current().languages
end

function M.is_enabled(name)
  return vim.list_contains(M.current().names, name)
end

function M.mason_options()
  local opts = { ensure_installed = {}, post_install = {}, tools = {} }
  for _, tool in ipairs(M.current().tools) do
    if tool.mason then
      opts.ensure_installed[#opts.ensure_installed + 1] = tool.mason
      opts.tools[tool.mason] = tool
      if tool.post_install then
        opts.post_install[tool.mason] = tool.post_install
      end
    end
  end
  return opts
end

return M
