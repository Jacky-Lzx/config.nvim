local api, uv = vim.api, vim.uv
local output = assert(vim.env.NVIM_WORKFLOW_RESULT)
local rounds = assert(tonumber(vim.env.NVIM_WORKFLOW_ROUNDS))
local records, step, round = {}, 0, 0
local client, buffer, probe
local function publish(value)
  vim.fn.writefile({ vim.json.encode(value) }, output .. ".next")
  assert(uv.fs_rename(output .. ".next", output))
end
local function fail(err)
  publish({ phase = "error", error = tostring(err), records = records })
  vim.cmd("cquit 1")
end
local function await(predicate, callback, timeout)
  local deadline = uv.hrtime() + (timeout or 15000) * 1e6
  local function poll()
    local ok, err = xpcall(function()
      if predicate() then
        callback()
      else
        assert(uv.hrtime() < deadline, "Workflow timed out at " .. debug.getinfo(predicate, "S").linedefined)
        vim.defer_fn(poll, 2)
      end
    end, debug.traceback)
    if not ok then
      fail(err)
    end
  end
  vim.schedule(poll)
end
local function stage(action, keys, predicate, callback)
  step = step + 1
  vim.cmd.redraw()
  publish({ phase = "input", step = step, action = action, round = round, keys = keys })
  await(predicate, function()
    vim.cmd.redraw()
    records[#records + 1] = { action = action, round = round, completed_ns = uv.hrtime() }
    publish({ phase = "completed", step = step, records = records })
    -- The parent acknowledges the completed frame before the next action.
    await(function()
      return vim.fn.filereadable(output .. ".ack") == 1
    end, function()
      vim.fn.delete(output .. ".ack")
      callback()
    end)
  end)
end
local next_round
local function probe_diagnostic()
  for _, diagnostic in ipairs(vim.diagnostic.get(buffer)) do
    if diagnostic.message:find("Unclosed environment `nvimbenchmarkenv`", 1, true) then
      return true
    end
  end
  return false
end
local function diagnose()
  -- Previous reports must clear before the same probe is inserted again. A
  -- cached diagnostic would otherwise make later rounds look artificially fast.
  await(function()
    return not probe_diagnostic()
  end, function()
    local row
    for index, line in ipairs(api.nvim_buf_get_lines(buffer, 0, -1, false)) do
      if line:find("\\end{document}", 1, true) then
        row = index - 1
      end
    end
    assert(row, "TeX workload has no document end")
    api.nvim_buf_set_lines(buffer, row, row, false, { "\\begin{nvimbenchmarkenv}" })
    local started = uv.hrtime()
    await(probe_diagnostic, function()
      vim.cmd.redraw()
      records[#records + 1] = {
        action = "diagnostic_refresh",
        round = round,
        elapsed_ms = (uv.hrtime() - started) / 1e6,
        diagnostics = #vim.diagnostic.get(buffer),
      }
      api.nvim_buf_set_lines(buffer, row, row + 1, false, {})
      next_round()
    end, 15000)
  end, 15000)
end
next_round = function()
  round = round + 1
  if round > rounds then
    assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
    publish({
      phase = "done",
      records = records,
      client = { name = client.name, cmd = client.config.cmd },
      lines = api.nvim_buf_line_count(buffer),
      bytes = api.nvim_buf_get_offset(buffer, api.nvim_buf_line_count(buffer)),
    })
    vim.cmd("qa!")
    return
  end
  for index, line in ipairs(api.nvim_buf_get_lines(buffer, 0, -1, false)) do
    if line == "% NVIM_WORKFLOW_PROBE" then
      probe = index
    end
  end
  assert(probe, "TeX workload has no probe marker")
  api.nvim_buf_set_lines(buffer, probe, probe + 2, false, { "\\ref{}", "Benchmark text." })
  api.nvim_win_set_cursor(0, { probe + 1, 5 })
  stage("completion", "isect", function()
    local cmp = package.loaded.completion_tools
    if not cmp or not cmp.is_menu_visible() then
      return false
    end
    for _, item in ipairs(cmp.get_items()) do
      if item._client_id == client.id then
        return true
      end
    end
    return false
  end, function()
    local cmp = require("completion_tools")
    local label = cmp.get_items()[1].label
    local screen = {}
    for row = 1, vim.o.lines do
      local line = {}
      for col = 1, vim.o.columns do
        line[#line + 1] = vim.fn.screenstring(row, col)
      end
      screen[#screen + 1] = table.concat(line)
    end
    assert(table.concat(screen, "\n"):find(label, 1, true), "Completion result was not rendered")
    stage("leave_completion", "\27", function()
      return api.nvim_get_mode().mode == "n"
    end, function()
      api.nvim_win_set_cursor(0, { probe + 2, 0 })
      stage("burst", "i" .. string.rep("x", 200), function()
        return api.nvim_buf_get_lines(buffer, probe + 1, probe + 2, false)[1]:find(string.rep("x", 200), 1, true)
      end, function()
        stage("leave_insert", "\27", function()
          return api.nvim_get_mode().mode == "n"
        end, function()
          local written = false
          api.nvim_create_autocmd("BufWritePost", {
            buffer = buffer,
            once = true,
            callback = function()
              written = true
            end,
          })
          stage("save", ":write\r", function()
            return written
          end, diagnose)
        end)
      end)
    end)
  end)
end
api.nvim_create_autocmd("User", {
  pattern = "ConfigReady",
  once = true,
  callback = function()
    buffer = api.nvim_get_current_buf()
    await(function()
      client = vim.lsp.get_clients({ bufnr = buffer, name = "texquill" })[1]
      return client and client.initialized
    end, next_round, 30000)
  end,
})
