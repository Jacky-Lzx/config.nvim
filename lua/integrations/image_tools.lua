local M = {}
local function tex()
  if vim.tbl_contains({ "tex", "plaintex", "latex" }, vim.bo.filetype) and require("languages").is_enabled("latex") then
    return require("tex-tools")
  end
end

function M.preview()
  local tools = tex()
  if tools and tools.formula_at() then
    return tools.preview_formula()
  end
  return require("image_tools.bootstrap").ensure().hover()
end

function M.enabled()
  return require("image_tools.bootstrap").enabled()
end

function M.toggle()
  local enabled = require("image_tools.bootstrap").toggle()
  local tools = tex()
  if tools and tools.formula_info().enabled ~= enabled then
    tools.toggle_formula_preview()
  end
  return enabled
end

function M.setup()
  vim.keymap.set("n", "<leader>si", M.preview, { desc = "[Image] Preview image or formula on current line" })
  vim.keymap.set("n", "<leader>ui", M.toggle, { desc = "[Image] Toggle automatic preview" })
  require("keymap_tools").register("image-tools.toggle", {
    toggles = { { keys = "<leader>ui", name = "Automatic image preview", get = M.enabled } },
  })
end
return M
