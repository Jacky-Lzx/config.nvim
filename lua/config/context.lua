local M = {}
local active
local schema = require("config.selection_schema")

-- Fresh contexts are useful for validation without changing the running editor.
function M.resolve(selection)
  selection = schema.normalize(selection)
  return { selection = selection, languages = require("languages").resolve(selection) }
end

-- Choose once, before lazy.nvim imports specs. A later, different selection is an
-- error rather than a mixture of old language data and new workflow switches.
function M.initialize(selection)
  selection = schema.normalize(selection or require("config.selection"))
  if active then
    assert(vim.deep_equal(active.selection, selection), "Configuration already resolved; restart to change selection")
  else
    active = M.resolve(selection)
  end
  return active
end

function M.current()
  return active or M.initialize()
end

return M
