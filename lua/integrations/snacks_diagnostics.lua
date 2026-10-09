local M = {}

function M.setup(snacks)
  local diagnostics = require("features.lsp.diagnostics")
  for _, toggle in ipairs({
    {
      key = "<leader>td",
      id = "diagnostics",
      name = "Diagnostics",
      get = diagnostics.enabled,
      set = diagnostics.set_enabled,
    },
    {
      key = "<leader>tV",
      id = "virtual_lines",
      name = "Diagnostic virtual lines",
      get = diagnostics.virtual_lines_enabled,
      set = diagnostics.set_virtual_lines,
    },
    {
      key = "<leader>tv",
      id = "virtual_text",
      name = "Diagnostic text",
      get = diagnostics.virtual_text_enabled,
      set = diagnostics.set_virtual_text,
    },
  }) do
    snacks.toggle.new({ id = toggle.id, name = toggle.name, get = toggle.get, set = toggle.set }):map(toggle.key)
  end
end

return M
