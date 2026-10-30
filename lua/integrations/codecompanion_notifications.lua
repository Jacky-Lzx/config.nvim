-- Consumer-owned event adapter; notification-tools only supplies the task API.
local M = {}
local handles = {}

function M.setup()
  for _, handle in pairs(handles) do
    handle:cancel("Integration reset")
  end
  handles = {}
  local group = vim.api.nvim_create_augroup("CodeCompanionNotificationHooks", { clear = true })
  if not require("integrations.notification_tools").available() then
    return
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "CodeCompanionRequestStarted",
    group = group,
    callback = function(event)
      local data = event.data or {}
      if data.id == nil then
        return
      end
      -- Drop handles whose tasks have expired without a finish event.
      for id, handle in pairs(handles) do
        if not handle:is_active() then
          handles[id] = nil
        end
      end
      if handles[data.id] then
        handles[data.id]:cancel("Replaced")
      end
      local adapter = type(data.adapter) == "table" and data.adapter or {}
      local source = adapter.formatted_name or adapter.name or "CodeCompanion"
      if type(adapter.model) == "string" and adapter.model ~= "" then
        source = source .. " (" .. adapter.model .. ")"
      end
      handles[data.id] = require("notification-tools").progress({
        id = "codecompanion:" .. type(data.id) .. ":" .. tostring(data.id),
        title = "Requesting assistance",
        source = source,
        message = "In progress…",
      })
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    pattern = "CodeCompanionRequestFinished",
    group = group,
    callback = function(event)
      local data = event.data or {}
      local handle = handles[data.id]
      if handle then
        local status = data.status == "success" and "success" or data.status == "error" and "error" or "cancelled"
        handle:finish(nil, status)
        handles[data.id] = nil
      end
    end,
  })
end

return M
