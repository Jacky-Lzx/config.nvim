local M = {}
local active

local function normalize(selection)
  assert(type(selection) == "table", "Selection must be a table")
  assert(type(selection.profiles) == "table" and vim.islist(selection.profiles), "Selection.profiles must be a list")
  return {
    profiles = vim.deepcopy(selection.profiles),
    features = require("config.features").normalize(selection.features),
  }
end

-- Fresh contexts are useful for validation without changing the running editor.
function M.resolve(selection)
  selection = normalize(selection)
  return { selection = selection, languages = require("languages").resolve(selection) }
end

-- Choose once, before lazy.nvim imports specs. A later, different selection is an
-- error rather than a mixture of old language data and new workflow switches.
function M.initialize(selection)
  selection = normalize(selection or require("config.selection"))
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
