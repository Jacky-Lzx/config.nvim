-- Ordinary mappings only. No loading proxies or manager activation callbacks.
local M = { entries = {} }
function M.set(id, entries)
  entries = type(entries) == "function" and entries() or entries
  M.entries[id] = entries
  for _, entry in ipairs(entries) do
    assert(type(entry[1]) == "string", id .. ": a mapping needs a string left-hand side")
    if entry[2] ~= nil then
      local options = {}
      for key, value in pairs(entry) do
        if type(key) == "string" and key ~= "mode" and key ~= "ft" then
          options[key] = value
        end
      end
      options.silent = options.silent ~= false
      local function bind(buffer)
        vim.keymap.set(entry.mode or "n", entry[1], entry[2], vim.tbl_extend("force", options, { buffer = buffer }))
      end
      if entry.ft then
        local filetypes = type(entry.ft) == "table" and entry.ft or { entry.ft }
        vim.api.nvim_create_autocmd("FileType", {
          pattern = filetypes,
          callback = function(event)
            bind(event.buf)
          end,
        })
        for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
          if vim.list_contains(filetypes, vim.bo[buffer].filetype) then
            bind(buffer)
          end
        end
      else
        bind(nil)
      end
    end
  end
end
return M
