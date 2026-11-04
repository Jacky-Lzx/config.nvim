-- Personal integrations for ui-tools; providers remain lazy and own their data.
local M = {}
local api = vim.api
local counts, tasks_dirty = {}, true
local queue, copilot_status, copilot_callback
local task_symbols = { FAILURE = "󰅚 ", CANCELED = " ", SUCCESS = "󰄴 ", RUNNING = "󰑮 " }

local function features()
  return require("config.context").current().selection.features
end

local function copilot_state(ctx)
  local client = package.loaded["copilot.client"]
  if not client then
    return "unknown"
  end
  if client.is_disabled() or not client.buf_is_attached(ctx.buf) then
    return "disabled"
  end
  local status = package.loaded["copilot.status"]
  local state = status and status.data.status or ""
  if state == "Warning" then
    return "warning"
  end
  if state == "InProgress" then
    return "busy"
  end
  return "enabled"
end

function M.sections()
  local result = {
    a = { "mode" },
    b = { "branch", "diff", "diagnostics" },
    c = { { "filename", path = "tail" } },
    x = {},
    y = { "encoding", "fileformat", "filetype", "progress" },
    z = { "location" },
  }
  if features().ai then
    for _, entry in ipairs({
      { "enabled", " ", "DiagnosticOk" },
      { "disabled", " ", "Comment" },
      { "warning", " ", "DiagnosticWarn" },
      { "busy", " …", "Special" },
      { "unknown", " ", "DiagnosticError" },
    }) do
      local state, icon, color = unpack(entry)
      result.c[#result.c + 1] = {
        function(ctx)
          return copilot_state(ctx) == state and icon or ""
        end,
        color = color,
        priority = 30,
      }
    end
  end
  if features().tasks then
    for _, status in ipairs({ "FAILURE", "CANCELED", "SUCCESS", "RUNNING" }) do
      result.x[#result.x + 1] = {
        function()
          return (counts[status] or 0) > 0 and task_symbols[status] .. counts[status] or ""
        end,
        color = "Overseer" .. status,
        priority = 60,
      }
    end
  end
  result.x[#result.x + 1] = "recording"
  return result
end

local function update()
  if tasks_dirty then
    counts, tasks_dirty = {}, false
    local tasks = features().tasks and package.loaded["overseer.task_list"]
    if tasks then
      for _, task in ipairs(tasks.list_tasks({ include_ephemeral = true })) do
        counts[task.status] = (counts[task.status] or 0) + 1
      end
    end
  end
  local status = features().ai and package.loaded["copilot.status"]
  if status and status ~= copilot_status then
    if copilot_status then
      copilot_status.unregister_status_notification_handler(copilot_callback)
    end
    copilot_status = status
    copilot_callback = function()
      queue.request()
    end
    status.register_status_notification_handler(copilot_callback)
  end
  -- Refresh only custom text; cached diagnostic/LSP/Git snapshots stay valid.
  require("ui_tools.statusline").update()
end

-- Component selection stays in the config; ui-tools owns all window UI.
function M.winbar_options()
  return {
    exclude = { "lsp-tools-results", "dap-view", "dap-view-term", "dap-repl" },
    breadcrumbs = function(ctx)
      local tools = package.loaded["lsp-tools"]
      return tools and tools.breadcrumbs({ winid = ctx.win }) or ""
    end,
  }
end

function M.setup()
  if queue then
    queue.cancel()
  end
  if copilot_status then
    copilot_status.unregister_status_notification_handler(copilot_callback)
  end
  copilot_status, copilot_callback = nil, nil
  queue = require("ui_tools.bar").scheduler(30, update)
  tasks_dirty = true
  local group = api.nvim_create_augroup("ConfigBars", { clear = true })
  api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "OverseerListUpdate", "LazyLoad" },
    callback = function()
      tasks_dirty = true
      queue.request()
    end,
  })
  update()
end

function M.close()
  local ok, err = require("ui_tools.bufferline").close()
  if not ok and err then
    vim.notify(err, vim.log.levels.WARN, { title = "Buffer" })
  end
end

function M.restore()
  local ok, err = require("ui_tools.bufferline").restore()
  if not ok and err then
    vim.notify(err, vim.log.levels.WARN, { title = "Buffer" })
  end
end

return M
