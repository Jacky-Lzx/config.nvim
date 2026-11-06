local function check()
  local manager = require("config.plugins").manager
  local source = { "# Demand Markdown", "", "plain source", "", "- first", "- second" }
  local function cold()
    for _, id in ipairs({ "render-markdown.nvim", "peek.nvim" }) do
      assert(manager.states[id].phase == "registered", id .. " mounted before Markdown")
      assert(not vim.list_contains(require("plugin_tools.util").runtime_paths(), manager.graph.nodes[id].dir))
    end
    for name in pairs(package.loaded) do
      assert(
        not name:match("^render%-markdown") and name ~= "peek" and not name:match("^peek%."),
        "Early module: " .. name
      )
    end
    assert(vim.fn.exists(":MarkdownPreview") == 0)
  end
  local temp = assert(vim.env.NVIM_TEST_TMP)
  if vim.env.NVIM_TEST_MARKDOWN_DIRECT == "1" then
    assert(vim.bo.filetype == "markdown")
  else
    cold()
    vim.cmd.edit(temp .. "/unrelated.lua")
    cold()
    vim.fn.writefile(source, temp .. "/first.md")
    if vim.env.NVIM_TEST_MARKDOWN_WORKSPACE == "1" then
      -- Capture a workspace before the renderer has ever been mounted.
      vim.cmd("noautocmd edit " .. vim.fn.fnameescape(temp .. "/first.md"))
      vim.cmd("noautocmd setfiletype markdown")
      local workspace = require("workspace_tools")
      local entry, err = workspace.save({ name = "Markdown demand" })
      assert(entry, err)
      vim.cmd("bwipeout")
      cold()
      local restored, restore_err = workspace.restore(entry)
      assert(restored, restore_err)
    else
      vim.cmd.edit(temp .. "/first.md")
    end
  end
  local first = vim.api.nvim_get_current_buf()
  for _, id in ipairs({ "render-markdown.nvim", "peek.nvim" }) do
    assert(manager.states[id].phase == "ready" and manager.states[id].count == 1)
    assert(manager.states[id].reason == "FileType markdown")
  end
  local render = require("render-markdown.core.manager")
  local state = require("render-markdown.state")
  local peek = require("peek")
  assert(render.attached(first), "Renderer missed the first Markdown buffer")
  assert(not state.enabled and not state.get(first).enabled, "Rendering should remain opt-in")
  assert(not peek.is_open(), "Opening Markdown opened a Peek preview")
  assert(vim.fn.exists(":MarkdownPreview") == 2)

  -- Let work queued by plugin scripts finish before checking the disabled view.
  local settled = false
  vim.schedule(function()
    settled = true
  end)
  assert(
    vim.wait(2000, function()
      return settled
    end),
    "Markdown startup work did not settle"
  )
  local ns = require("render-markdown.core.ui").ns
  assert(#vim.api.nvim_buf_get_extmarks(first, ns, 0, -1, {}) == 0, "Disabled renderer drew Markdown")
  vim.cmd.redraw()
  if #vim.api.nvim_list_uis() > 0 then
    local position = vim.fn.screenpos(0, 5, 1)
    assert(vim.fn.screenstring(position.row, position.col) == "-", "Disabled view hid the source bullet")
  end

  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  vim.api.nvim_feedkeys(vim.keycode("<Space>tmr"), "xt", false)
  assert(state.enabled and state.get(first).enabled)
  assert(
    vim.wait(2000, function()
      return #vim.api.nvim_buf_get_extmarks(first, ns, 0, -1, {}) > 0
    end),
    "Renderer did not draw the first Markdown buffer"
  )
  vim.cmd.redraw()
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(first, 0, -1, false), source))
  vim.api.nvim_feedkeys(vim.keycode("<Space>tmr"), "xt", false)
  assert(not state.enabled)

  -- Exercise the real command/controller without launching an external viewer.
  local app = require("peek.app")
  local originals, observed = {}, {}
  for _, name in ipairs({ "init", "base", "show", "scroll", "stop" }) do
    originals[name] = app[name]
  end
  local exit
  app.init = function(callback)
    observed.opened, exit = true, callback
  end
  app.base = function(path)
    observed.base = path
  end
  app.show = function(text)
    observed.text = text
  end
  app.scroll = function(line)
    observed.line = line
  end
  app.stop = function()
    exit()
  end
  vim.cmd.MarkdownPreview()
  assert(observed.opened and observed.text == table.concat(source, "\n"))
  assert(observed.line == 3 and peek.is_open())
  peek.close()
  assert(not peek.is_open())
  for name, fn in pairs(originals) do
    app[name] = fn
  end

  vim.fn.writefile({ "# Second Markdown", "", "unchanged" }, temp .. "/second.md")
  vim.cmd.edit(temp .. "/second.md")
  assert(render.attached(vim.api.nvim_get_current_buf()), "Renderer missed a subsequent buffer")
  assert(not state.enabled and not peek.is_open())
  for _, id in ipairs({ "render-markdown.nvim", "peek.nvim" }) do
    assert(manager.states[id].count == 1, id .. " initialized twice")
  end
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
  io.stdout:write(
    "Markdown demand: cold startup/Lua, first/repeated buffers, rendering toggle and Peek command passed\n"
  )
end

local function run()
  local ok, err = xpcall(check, debug.traceback)
  if vim.env.NVIM_STARTUP_RESULT then
    vim.fn.writefile({ ok and "passed" or tostring(err) }, vim.env.NVIM_STARTUP_RESULT)
  end
  if not ok then
    io.stderr:write(err .. "\n")
  end
  vim.cmd(ok and "qa!" or "cquit 1")
end
if vim.g.config_ready then
  vim.schedule(run)
else
  vim.api.nvim_create_autocmd("User", {
    pattern = "ConfigReady",
    once = true,
    callback = function()
      vim.schedule(run)
    end,
  })
end
