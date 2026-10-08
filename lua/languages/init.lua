local M = {}
local definitions = { lua = "languages.lua" }

function M.selected()
  local records = {}
  for _, name in ipairs(vim.tbl_keys(definitions)) do
    if require("config.settings").current().languages[name] then
      local record = vim.deepcopy(require(definitions[name]))
      record.language = name
      records[#records + 1] = record
    end
  end
  table.sort(records, function(a, b)
    return a.language < b.language
  end)
  return records
end

return M
