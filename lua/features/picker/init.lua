local M = {}
local mappings = {
  { "<leader>sf", "files", "Find files" },
  { "<leader>sg", "grep", "Grep" },
  { "<leader>sb", "buffers", "Buffers" },
  { "<leader>,", "buffers", "Buffers" },
  { "<leader>sR", "recent", "Recent" },
  { "<leader>sr", "resume", "Resume" },
  { "<leader>sd", "diagnostics", "Diagnostics" },
  { "<leader>sD", "diagnostics_buffer", "Diagnostics buffer" },
  { "gd", "lsp_definitions", "Goto definition" },
  { "gD", "lsp_declarations", "Goto declaration" },
  { "gi", "lsp_references", "References" },
  { "gI", "lsp_implementations", "Goto implementation" },
  { "gy", "lsp_type_definitions", "Goto type definition" },
  { "gci", "lsp_incoming_calls", "Calls incoming" },
  { "gco", "lsp_outgoing_calls", "Calls outgoing" },
  { "<leader>ss", "lsp_symbols", "LSP symbols" },
  { "<leader>sS", "lsp_workspace_symbols", "LSP workspace symbols" },
}

function M.requirements()
  return { { "snacks.nvim", "lua/snacks/init.lua" } }
end

function M.specs()
  local keys = {}
  for _, mapping in ipairs(mappings) do
    local source = mapping[2]
    keys[#keys + 1] = {
      mapping[1],
      function()
        if require("features.picker.tools").usable(source) then
          require("snacks").picker[source]()
        end
      end,
      mode = "n",
      desc = "[Snacks] " .. mapping[3],
    }
  end
  return {
    {
      "folke/snacks.nvim",
      lazy = true,
      keys = keys,
      opts = { picker = require("features.picker.options").get() },
    },
  }
end

return M
