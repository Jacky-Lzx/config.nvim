local api = vim.api
local output = assert(vim.env.NVIM_BENCH_RESULT)
local action = assert(vim.env.NVIM_BENCH_ACTION)
local ready, finished, picker = false, false, nil
local function snapshot(phase)
  local manager = require("config.plugins").manager
  local completion = package.loaded.completion_tools
  local record = {
    phase = phase,
    filetype = vim.bo.filetype,
    resolve_ms = manager.timings.resolve_ms,
    register_ms = manager.timings.start_ms,
    completion = completion and completion.get_status().configured or false,
    completion_loaded = completion ~= nil,
    completion_ui_loaded = package.loaded["completion_tools.ui"] ~= nil,
    snippets = package.loaded.snippet_tools ~= nil,
    images = package.loaded.image_tools ~= nil,
    picker = picker ~= nil,
    mode = api.nvim_get_mode().mode,
  }
  vim.fn.writefile({ vim.json.encode(record) }, output .. ".next")
  assert(vim.uv.fs_rename(output .. ".next", output))
end
local function finish()
  if finished then
    return
  end
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
  finished = true
  vim.cmd.redraw()
  snapshot("action")
  if picker then
    picker:close()
  end
  vim.defer_fn(function()
    vim.cmd("qa!")
  end, 5)
end
local event = action == "insert" and "InsertEnter" or "CmdlineEnter"
if action ~= "picker" then
  api.nvim_create_autocmd(event, {
    once = true,
    callback = function()
      if ready then
        vim.schedule(finish)
      end
    end,
  })
else
  local selection = require("selection_tools")
  local files = selection.files
  selection.files = function(...)
    picker = files(...)
    local timer = vim.uv.new_timer()
    timer:start(
      0,
      1,
      vim.schedule_wrap(function()
        if not picker.loading and not picker.matching and #picker.matches > 0 then
          timer:stop()
          timer:close()
          finish()
        end
      end)
    )
    return picker
  end
end
api.nvim_create_autocmd("User", {
  pattern = "ConfigReady",
  once = true,
  callback = function()
    local ok, err = xpcall(function()
      local completion = package.loaded.completion_tools
      assert(
        not (completion and completion.get_status().configured)
          and not package.loaded.snippet_tools
          and not package.loaded.image_tools
      )
      ready = true
      vim.cmd.redraw()
      snapshot("startup")
    end, debug.traceback)
    if not ok then
      vim.fn.writefile({ vim.json.encode({ phase = "error", error = err }) }, output)
      vim.cmd("cquit 1")
    end
  end,
})
