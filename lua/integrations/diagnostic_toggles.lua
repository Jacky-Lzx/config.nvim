local M = {}
function M.setup()
  local entries = {}
  for _, owner in ipairs(require("features.lsp.diagnostics").toggles()) do
    entries[#entries + 1] = require("features.toggles").metadata(owner.id, owner.get)
  end
  require("keymap_tools").register("diagnostics", { toggles = entries })
end
return M
