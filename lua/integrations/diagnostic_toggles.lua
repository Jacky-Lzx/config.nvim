local M = {}

function M.setup()
  local diagnostics = require("features.lsp.diagnostics")
  require("keymap_tools").register("diagnostics", {
    toggles = {
      {
        keys = "<leader>td",
        name = "Diagnostics",
        get = diagnostics.enabled,
      },
      {
        keys = "<leader>tV",
        name = "Diagnostic virtual lines",
        get = diagnostics.virtual_lines_enabled,
      },
      {
        keys = "<leader>tv",
        name = "Diagnostic text",
        get = diagnostics.virtual_text_enabled,
      },
    },
  })
end

return M
