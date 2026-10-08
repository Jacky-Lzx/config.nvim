local M = {}

local fields = {
  servers = true,
  parsers = true,
  tools = true,
  plugins = true,
  formatters = true,
  formatter_options = true,
  linters = true,
  linter_options = true,
  requires = true,
}
local tool_fields =
  { mason = "string", executable = "string", resolve = "function", feature = "string", post_install = "function" }

local function check(ok, path, message)
  assert(ok, path .. ": " .. message)
end

local function string_value(value, path)
  check(type(value) == "string" and value ~= "", path, "expected a non-empty string")
end

local function list(value, path, strings)
  check(type(value) == "table" and vim.islist(value), path, "expected a list")
  if strings then
    for i, item in ipairs(value) do
      string_value(item, path .. "[" .. i .. "]")
    end
  end
end

function M.validate(name, definition)
  local path = "languages." .. name
  check(type(definition) == "table", path, "expected a table")
  for field in pairs(definition) do
    check(fields[field], path .. "." .. tostring(field), "unknown field")
  end
  for _, field in ipairs({ "servers", "parsers", "tools", "plugins" }) do
    if definition[field] ~= nil then
      list(definition[field], path .. "." .. field, field == "servers" or field == "parsers")
    end
  end
  for i, tool in ipairs(definition.tools or {}) do
    local tool_path = path .. ".tools[" .. i .. "]"
    check(type(tool) == "table", tool_path, "expected a table")
    for field, value in pairs(tool) do
      check(tool_fields[field] ~= nil, tool_path .. "." .. tostring(field), "unknown field")
      check(type(value) == tool_fields[field], tool_path .. "." .. field, "expected " .. tool_fields[field])
      if type(value) == "string" then
        string_value(value, tool_path .. "." .. field)
      end
    end
    check(tool.executable or tool.resolve, tool_path, "needs an executable or resolver")
    check(tool.executable or tool.mason, tool_path, "resolver-only tools need a Mason package name")
    if tool.feature then
      check(
        vim.list_contains(require("config.features").names, tool.feature),
        tool_path .. ".feature",
        "unknown feature"
      )
    end
    check(not tool.post_install or tool.mason, tool_path .. ".post_install", "needs a Mason package name")
  end
  for i, spec in ipairs(definition.plugins or {}) do
    check(
      type(spec) == "string" or type(spec) == "table",
      path .. ".plugins[" .. i .. "]",
      "expected a native lazy spec"
    )
  end
  for _, field in ipairs({ "formatters", "formatter_options", "linters", "linter_options" }) do
    if definition[field] ~= nil then
      check(type(definition[field]) == "table", path .. "." .. field, "expected a table")
      for key, value in pairs(definition[field]) do
        string_value(key, path .. "." .. field)
        check(type(value) == "table", path .. "." .. field .. "." .. key, "expected a table")
        if field == "formatters" or field == "linters" then
          for index, item in ipairs(value) do
            string_value(item, path .. "." .. field .. "." .. key .. "[" .. index .. "]")
          end
        end
      end
    end
  end
  if definition.requires ~= nil then
    check(type(definition.requires) == "table", path .. ".requires", "expected a table")
    for field, bindings in pairs(definition.requires) do
      check(field == "formatters" or field == "linters", path .. ".requires." .. tostring(field), "unknown field")
      check(type(bindings) == "table", path .. ".requires." .. field, "expected a table")
      for key, executable in pairs(bindings) do
        string_value(key, path .. ".requires." .. field)
        string_value(executable, path .. ".requires." .. field .. "." .. key)
        check(
          definition[field] and definition[field][key],
          path .. ".requires." .. field .. "." .. key,
          "has no binding"
        )
      end
    end
  end
end

return M
