local M = {}

function M.branch()
  local name = vim.b.gitsigns_head or ""
  return (name:gsub("%%", "%%%%"))
end

function M.diff()
  local status = vim.b.gitsigns_status_dict
  if status then
    return { added = status.added, modified = status.changed, removed = status.removed }
  end
end

function M.recording()
  local register = vim.fn.reg_recording()
  return register ~= "" and "󰑋 " .. register or ""
end

return M
