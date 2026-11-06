-- Personal integrations for ui-tools; providers remain lazy and own their data.
local M = {}
local api = vim.api
local counts, tasks_dirty = {}, true
local queue
local function task_symbol(status)
  local shared = package.loaded["theme_tools.icons"]
  local icon = shared and shared.get("task", status) or ""
  return icon ~= "" and icon .. " " or status .. " "
end
local task_colors =
  { failure = "DiagnosticError", stopped = "Comment", success = "DiagnosticOk", running = "DiagnosticInfo" }

local function features()
  return require("config.context").current().selection.features
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
  if features().tasks then
    for _, status in ipairs({ "failure", "stopped", "success", "running" }) do
      result.x[#result.x + 1] = {
        function()
          return (counts[status] or 0) > 0 and task_symbol(status) .. counts[status] or ""
        end,
        color = task_colors[status],
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
    local tasks = features().tasks and package.loaded.task_tools
    if tasks then
      counts = tasks.status()
      counts.running = counts.running + counts.stopping
    end
  end
  -- Refresh only custom text; cached diagnostic/LSP/Git snapshots stay valid.
  require("ui_tools.statusline").update()
end

-- Component selection stays in the config; ui-tools owns all window UI.
function M.winbar_options()
  return {
    exclude = { "file-tools", "lsp-tools-results", "daptools", "dap-repl" },
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
  queue = require("ui_tools.bar").scheduler(30, update)
  tasks_dirty = true
  local group = api.nvim_create_augroup("ConfigBars", { clear = true })
  api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "TaskToolsChanged", "ConfigReady", "ThemeToolsReady", "ThemeToolsIconsChanged" },
    callback = function(event)
      if event.match == "TaskToolsChanged" and event.data and event.data.kind == "output" then
        return
      end
      if event.match == "TaskToolsChanged" or event.match == "ConfigReady" then
        tasks_dirty = true
      end
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
