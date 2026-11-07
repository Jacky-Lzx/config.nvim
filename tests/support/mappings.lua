-- Audit configured mapping ownership without using mappings to drive workflows.
local M = {}
local aliases = { v = { "x", "s" }, [""] = { "n", "x", "s", "o" }, ["!"] = { "i", "c" } }
local function modes(entry)
  local result = {}
  for _, mode in ipairs(type(entry.mode) == "table" and entry.mode or { entry.mode or "n" }) do
    vim.list_extend(result, aliases[mode] or { mode })
  end
  return result
end
local function check(entry, mode, label)
  local actual = vim.fn.maparg(entry[1], mode, false, true)
  local target = entry.buffer
  local local_map = entry.ft or (target ~= nil and target ~= false)
  if type(target) == "number" and target ~= 0 then
    assert(target == vim.api.nvim_get_current_buf(), "Action targets a different buffer: " .. label)
  end
  assert(actual.lhs and (actual.buffer == 1) == not not local_map, "Wrong mapping scope: " .. label)
  assert(actual.expr == (entry.expr and 1 or 0), "Wrong expression mapping: " .. label)
  assert(actual.nowait == (entry.nowait and 1 or 0), "Wrong prefix waiting policy: " .. label)
  assert(
    type(entry[2]) == "function" and actual.callback == entry[2]
      or type(entry[2]) == "string" and vim.keycode(actual.rhs or "") == vim.keycode(entry[2]),
    "Action mapping was replaced: " .. label
  )
end
function M.audit()
  local count = 0
  for owner, entries in pairs(require("config.bindings").entries) do
    for _, entry in ipairs(entries) do
      local filetypes = type(entry.ft) == "table" and entry.ft or { entry.ft }
      local target = entry.buffer
      if
        entry[2] ~= nil
        and (not entry.ft or vim.list_contains(filetypes, vim.bo.filetype))
        and (type(target) ~= "number" or target == 0 or target == vim.api.nvim_get_current_buf())
      then
        for _, mode in ipairs(modes(entry)) do
          check(entry, mode, owner .. ": " .. entry[1] .. " (" .. mode .. ")")
          count = count + 1
        end
      end
    end
  end
  return count
end

return M
