-- Actual configured startup and physical terminal input via tests/support/tui.py.
local api = vim.api
local stage = vim.env.NVIM_TEST_TMP .. "/annotations-stage"
local colors, todo, buffer

local function marks(module, kind)
  return api.nvim_buf_get_extmarks(buffer, module.ns, 0, -1, { details = true, type = kind })
end

local function finish(ok, message)
  vim.fn.writefile(vim.split(message, "\n", { plain = true }), vim.env.NVIM_STARTUP_RESULT)
  vim.cmd(ok and "quitall!" or "cquit 1")
end

local function checked(callback)
  local ok, err = xpcall(callback, debug.traceback)
  if not ok then
    finish(false, err)
  end
end

local function await(predicate, callback)
  local attempts = 100
  local function poll()
    checked(function()
      if predicate() then
        callback()
      elseif attempts == 0 then
        error("Annotation input/update timed out at " .. table.concat(vim.fn.readfile(stage), ""))
      else
        attempts = attempts - 1
        vim.defer_fn(poll, 20)
      end
    end)
  end
  vim.defer_fn(poll, 20)
end

local function swatches_visible()
  vim.cmd("redraw!")
  for row = 1, vim.o.lines - 1 do
    for col = 1, vim.o.columns do
      if vim.fn.screenstring(row, col) == "■" then
        return true
      end
    end
  end
  return false
end

local function verify_toggles()
  local ui = require("ui_tools")
  local column = require("ui_tools.statuscolumn")
  ui.toggle("todo")
  assert(#marks(todo) == 0 and #marks(colors) == 3, "TODO toggle affected color previews")
  local rows = column.cache[api.nvim_get_current_win()] or {}
  for _, row in pairs(rows) do
    local sign = row.other_sign or row.sign
    assert(not sign or sign.ns_id ~= todo.ns, "TODO sign remained cached")
  end
  ui.toggle("todo")
  assert(#marks(todo, "sign") == 2)
  ui.toggle("colors")
  assert(#marks(colors) == 0 and #marks(todo, "sign") == 2, "Color toggle affected TODO annotations")
  ui.toggle("colors")
  assert(#marks(colors) == 3 and swatches_visible())
  local before = api.nvim_buf_get_lines(buffer, 0, -1, false)
  vim.cmd("enew!")
  colors.refresh()
  todo.refresh()
  assert(#marks(colors) == 0 and #marks(todo) == 0, "Hidden source kept annotations")
  api.nvim_set_current_buf(buffer)
  colors.refresh()
  todo.refresh()
  assert(#marks(colors) == 3 and #marks(todo, "sign") == 2)
  assert(vim.deep_equal(before, api.nvim_buf_get_lines(buffer, 0, -1, false)), "Annotations changed source text")
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
  finish(
    true,
    "Configured annotations: startup ownership, swatches, comment filtering, Insert updates, 200-character burst, independent toggles, hidden buffers and source preservation passed"
  )
end

local function check()
  assert(vim.g.config_ready)
  local plugins = require("config.plugins").nodes()
  assert(require("config.plugins").initialized("ui-tools.nvim"))
  assert(not plugins["nvim-highlight-colors"] and not plugins["todo-comments.nvim"])
  assert(not package.loaded["nvim-highlight-colors"] and not package.loaded["todo-comments"])
  colors, todo = require("ui_tools.colors"), require("ui_tools.todo")
  assert(colors.enabled and todo.enabled, "Configured annotation modules must start automatically")
  assert(colors.options.style == "inline" and colors.options.symbol == "■")
  local path = vim.env.NVIM_TEST_TMP .. "/annotations.lua"
  vim.fn.writefile({ "-- TODO(lzx): implement #123456", "local s = 'TODO: ordinary string'", "-- plain" }, path)
  vim.cmd.edit(path)
  buffer = api.nvim_get_current_buf()
  assert(vim.wait(1500, function()
    return #marks(colors) == 1 and #marks(todo, "sign") == 1
  end))
  assert(marks(todo, "sign")[1][2] == 0, "Quoted TODO text was marked")
  local swatch = marks(colors)[1][4].virt_text[1]
  assert(swatch[1] == "■ " and api.nvim_get_hl(0, { name = swatch[2], link = false }).fg == 0x123456)
  assert(swatches_visible(), "Configured inline swatch was not drawn")
  vim.fn.writefile({ "insert" }, stage)
  await(function()
    return vim.fn.mode() == "i" and #marks(colors) == 2 and #marks(todo, "sign") == 2
  end, function()
    vim.fn.writefile({ "burst" }, stage)
    await(function()
      return vim.fn.mode() == "i" and #marks(colors) == 3
    end, function()
      assert(api.nvim_buf_get_lines(buffer, 2, 3, false)[1]:find(string.rep("x", 200), 1, true))
      vim.fn.writefile({ "normal" }, stage)
      await(function()
        return vim.fn.mode() == "n"
      end, verify_toggles)
    end)
  end)
end

api.nvim_create_autocmd("User", {
  pattern = "ConfigReady",
  once = true,
  callback = function()
    vim.defer_fn(function()
      checked(check)
    end, 120)
  end,
})
