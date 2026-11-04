-- Personal integrations for ui-tools; providers remain lazy and own their data.
local M = {}
local api = vim.api
local expression = "%!v:lua.require'features.bars'.winbar()"
local owned, blocked, buffers, cache, client_dirty = {}, {}, {}, {}, {}
local counts, tasks_dirty = {}, true
local queue, copilot_status, copilot_callback
local excluded = { "lsp-tools-results", "dap-view", "dap-view-term", "dap-repl" }
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

local function set_winbar(win, value)
  local old = vim.wo[win].winbar
  if (old == "") ~= (value == "") then
    require("ui_tools.bar").preserve_views(function()
      vim.wo[win].winbar = value
    end)
  else
    vim.wo[win].winbar = value
  end
end

local function update()
  local bar = require("ui_tools.bar")
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
  local used = {}
  for _, win in ipairs(api.nvim_list_wins()) do
    local buf = api.nvim_win_get_buf(win)
    local suitable = api.nvim_win_get_config(win).relative == ""
      and vim.bo[buf].buftype == ""
      and not vim.tbl_contains(excluded, vim.bo[buf].filetype)
      and not vim.b[buf].ui_tools_disable
    if not suitable then
      if owned[win] ~= nil and vim.wo[win].winbar == expression then
        set_winbar(win, owned[win])
      end
      owned[win], buffers[win] = nil, nil
    elseif owned[win] ~= nil and vim.wo[win].winbar ~= expression then
      -- A buffer switch may restore an empty native winbar. A deliberate
      -- change in the same buffer or a custom provider still wins ownership.
      if buffers[win] == buf or vim.wo[win].winbar ~= "" then
        owned[win], buffers[win], blocked[win] = nil, nil, true
      end
    end
    if
      suitable
      and not blocked[win]
      and (owned[win] ~= nil or vim.wo[win].winbar == "" or vim.wo[win].winbar == expression)
    then
      local data = cache[buf]
      if not data or client_dirty[buf] then
        local clients = {}
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
          clients[#clients + 1] = client.name
        end
        table.sort(clients)
        data = { clients = bar.escape(table.concat(clients, ", ")) }
        cache[buf] = data
      end
      local name = vim.fn.fnamemodify(api.nvim_buf_get_name(buf), ":t")
      data.name = bar.text(name == "" and "[No Name]" or name)
      used[buf] = true
      owned[win], buffers[win] = owned[win] or "", buf
      -- Changing visibility can redraw synchronously to preserve the view.
      -- Populate the new buffer's data before exposing the bar to that redraw.
      if vim.wo[win].winbar ~= expression then
        set_winbar(win, expression)
      end
    end
  end
  for win in pairs(owned) do
    if not api.nvim_win_is_valid(win) then
      owned[win], buffers[win] = nil, nil
    end
  end
  for win in pairs(blocked) do
    if not api.nvim_win_is_valid(win) then
      blocked[win] = nil
    end
  end
  for buf in pairs(cache) do
    if not used[buf] then
      cache[buf] = nil
    end
  end
  client_dirty = {}
  -- Refresh only custom text; cached diagnostic/LSP/Git snapshots stay valid.
  require("ui_tools.statusline").update()
  vim.cmd("redrawstatus")
end

function M.winbar()
  local win = tonumber(vim.g.statusline_winid) or api.nvim_get_current_win()
  if not api.nvim_win_is_valid(win) or win ~= api.nvim_get_current_win() then
    return " "
  end
  local data = cache[api.nvim_win_get_buf(win)]
  if not data then
    return " "
  end
  local bar = require("ui_tools.bar")
  local tools = package.loaded["lsp-tools"]
  local crumbs = tools and tools.breadcrumbs({ winid = win }) or ""
  local width = math.max(1, math.floor(api.nvim_win_get_width(win) * 0.45))
  return " "
    .. bar.label(bar.truncate(data.name, width), "Directory")
    .. " "
    .. crumbs
    .. "%=%#WinBar#"
    .. data.clients
    .. " "
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
  api.nvim_create_autocmd({ "BufWinEnter", "BufFilePost", "WinEnter", "TabEnter", "FileType" }, {
    group = group,
    -- Restore window options and refresh buffer data before the first redraw.
    -- Deferring this exposes a missing winbar or the previous buffer's cache.
    callback = update,
  })
  api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function()
      queue.request()
    end,
  })
  api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
    group = group,
    callback = function(args)
      client_dirty[args.buf] = true
      queue.request()
    end,
  })
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
