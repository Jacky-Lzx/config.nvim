local M = {}
local installed = false

-- Obsidian callbacks receive a list; vim.ui.select returns one item or nil.
function M.setup()
  if installed then
    return
  end
  local picker = require("obsidian.picker.default")
  local native_select = picker.select
  local supported = { prompt = true, kind = true, format_item = true }
  picker.select = function(items, opts, on_choice)
    opts = opts or {}
    -- Keep previews, multi-selection and picker-specific mappings intact.
    for key in pairs(opts) do
      if not supported[key] then
        return native_select(items, opts, on_choice)
      end
    end
    return vim.ui.select(items, opts, function(item)
      on_choice(item == nil and {} or { item })
    end)
  end
  installed = true
end

return M
