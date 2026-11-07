-- Personal group choices; completion-tools owns buffer-local selection state.
local M = {}
function M.code_sources()
  return { "lsp", "path" }
end
for _, method in ipairs({ "sources", "active_sources", "cycle", "toggle_source" }) do
  M[method] = function(config, ...)
    return require("completion_tools.source_selection")[method](config, ...)
  end
end
return M
