-- Configuration-side Noice adapter using the public notification API.
package.preload["noice.view.backend.notification_tools"] = function()
  local View = require("noice.view")
  local ToolsView = View:extend("NotificationToolsView")

  function ToolsView:show()
    local tools = require("notification-tools")
    local messages = self._messages
    self:clear()
    for _, message in ipairs(messages) do
      local opts = message.opts or {}
      self.notification_id = tools.notify(message:content(), self._opts.level or message.level, {
        id = opts.id and ("noice:" .. tostring(opts.id)) or (self._opts.replace and self.notification_id or nil),
        title = opts.title or self._opts.title or "Noice",
        timeout = opts.timeout or self._opts.timeout,
      })
    end
  end

  function ToolsView:hide() end

  function ToolsView.dismiss()
    require("notification-tools").dismiss()
  end

  return ToolsView
end

return { notify = { backend = "notification_tools" } }
