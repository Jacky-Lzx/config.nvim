-- Resolve declared actions, then verify the effective editor mapping independently.
-- Descriptions and physical keys are preferences, not action identities.
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
function M.binding(id, mode)
  mode = mode or "n"
  local found
  for owner, entries in pairs(require("config.bindings").entries) do
    for _, entry in ipairs(entries) do
      local filetypes = type(entry.ft) == "table" and entry.ft or { entry.ft }
      if
        entry.id == id
        and vim.list_contains(modes(entry), mode)
        and (not entry.ft or vim.list_contains(filetypes, vim.bo.filetype))
      then
        assert(not found, "Ambiguous action: " .. id .. " (" .. mode .. ")")
        found = { owner = owner, entry = entry, lhs = entry[1] }
      end
    end
  end
  assert(found, "Missing declared action: " .. id .. " (" .. mode .. ")")
  check(found.entry, mode, id)
  return found
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
          check(entry, mode, owner .. ": " .. (entry.id or entry[1]) .. " (" .. mode .. ")")
          count = count + 1
        end
      end
    end
  end
  return count
end

function M.keys(id, mode)
  return vim.keycode(M.binding(id, mode).lhs)
end
-- PTYs take terminal bytes rather than Neovim's internal K_SPECIAL encoding.
-- Fail explicitly for unsupported terminals/keys instead of bypassing real input.
function M.input(id, mode)
  local lhs = M.binding(id, mode).lhs
  lhs = lhs
    :gsub("<[Ll][Ee][Aa][Dd][Ee][Rr]>", function()
      return vim.g.mapleader or "\\"
    end)
    :gsub("<[Ll][Oo][Cc][Aa][Ll][Ll][Ee][Aa][Dd][Ee][Rr]>", function()
      return vim.g.maplocalleader or "\\"
    end)
  return (
    lhs:gsub("<([^>]+)>", function(token)
      local simple = { space = " ", cr = "\r", enter = "\r", esc = "\27", tab = "\t", bs = "\127", lt = "<" }
      local lower = token:lower()
      if simple[lower] then
        return simple[lower]
      end
      local modifier, char = token:match("^([CAMcam])%-(.)$")
      if modifier then
        if modifier:lower() == "c" then
          return string.char(char:upper():byte() % 32)
        end
        return "\27" .. char
      end
      error("Unsupported PTY key in action " .. id .. ": <" .. token .. ">")
    end)
  )
end
return M
