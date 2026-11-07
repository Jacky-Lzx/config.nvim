local M = {}
local function tex()
  if vim.tbl_contains({ "tex", "plaintex", "latex" }, vim.bo.filetype) and require("languages").is_enabled("latex") then
    return require("tex-tools")
  end
end
function M.preview()
  local tools = tex()
  if tools then
    return tools.preview()
  end
  return require("image_tools.bootstrap").ensure().hover()
end
function M.enabled()
  return require("image_tools.bootstrap").enabled()
end
function M.set_enabled(state)
  require("image_tools.bootstrap").set_auto_preview(state)
  local tools = package.loaded["tex-tools"]
  if tools then
    tools.set_auto_preview(state)
  end
  return state
end
function M.toggle()
  return M.set_enabled(not M.enabled())
end
function M.setup()
  vim.keymap.set("n", "<leader>si", M.preview, { desc = "[Image] Preview image or formula on current line" })
  require("features.toggles").map({ id = "image_preview", scope = "session", get = M.enabled, action = M.toggle })
end
return M
