-- Native LaTeX collections; the pre-migration baseline lives in tests/fixtures.
local result = {}
for _, name in ipairs({ "beamer", "environments", "math", "text" }) do
  -- dofile intentionally re-executes children when :SnippetToolsReload is used.
  local path = require("utils.paths").config("lua", "snippet_collections", "tex", name .. ".lua")
  vim.list_extend(result, dofile(path))
end
return result
