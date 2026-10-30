-- Invoked by tests/tui.py after the full real configuration has started.
local tools = require("notification-tools")
local result = assert(vim.env.NVIM_LAZY_RESULT)
local original_win, original_buf, notice, before
local failed = false
local function finish(ok, message)
  if failed then
    return
  end
  failed = not ok
  vim.fn.writefile(vim.split(message, "\n", { plain = true }), result)
  vim.cmd(ok and "qa!" or "cquit 1")
end
local function later(ms, callback)
  vim.defer_fn(function()
    if failed then
      return
    end
    local ok, err = xpcall(callback, debug.traceback)
    if not ok then
      finish(false, err)
    end
  end, ms)
end
local function floats()
  local windows = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "notification-tools" then
      windows[win] = buf
    end
  end
  return windows
end
local function capture()
  vim.cmd.redraw()
  local rows = {}
  for row = 1, vim.o.lines do
    local line = {}
    for col = 1, vim.o.columns do
      line[#line + 1] = vim.fn.screenstring(row, col)
    end
    rows[row] = table.concat(line)
  end
  vim.fn.writefile(rows, vim.env.NVIM_TEST_TMP .. "/notifications-screen.txt")
  return table.concat(rows, "\n")
end

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    later(100, function()
      assert(vim.g.did_very_lazy and #vim.api.nvim_list_uis() > 0)
      assert(not require("lazy.core.config").plugins["fidget.nvim"])
      assert(not require("lazy.core.config").plugins["noice.nvim"] and not package.loaded.noice)
      assert(require("input-tools").status().notifications, "Native message handoff is inactive")
      tools.dismiss()
      tools.clear_tasks()
      tools.clear_history()
      original_win = vim.api.nvim_get_current_win()
      original_buf = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_win_set_buf(original_win, original_buf)
      vim.api.nvim_buf_set_lines(original_buf, 0, -1, false, { "" })
      notice = vim.notify("中文通知", "info", { title = "Build", timeout = 0 })
      require("integrations.codecompanion_notifications").setup()
      vim.api.nvim_exec_autocmds("User", {
        pattern = "CodeCompanionRequestStarted",
        data = { id = "tui", adapter = { formatted_name = "External API" } },
      })
      -- Native LSP notices use vim.notify; native warning messages use the message handoff.
      local get_client = vim.lsp.get_client_by_id
      vim.lsp.get_client_by_id = function(id)
        return id == 987654 and { name = "notification-test" } or get_client(id)
      end
      assert(type(vim.lsp.handlers["window/showMessage"]) == "function")
      vim.lsp.handlers["window/showMessage"](
        nil,
        { type = 2, message = "Native LSP warning" },
        { client_id = 987654 }
      )
      vim.lsp.get_client_by_id = get_client
      vim.api.nvim_echo({ { "Native warning route", "WarningMsg" } }, true, { kind = "wmsg" })
    end)
    later(500, function()
      assert(vim.tbl_count(floats()) == 4, "Expected three notifications and a task panel")
      assert(vim.api.nvim_get_current_win() == original_win)
      local text = capture()
      assert(text:find("中文通知", 1, true) and text:find("Requesting assistance", 1, true))
      assert(text:find("Native LSP warning", 1, true), "The native LSP handler did not route the message")
      assert(text:find("Native warning route", 1, true), "Native messages did not route the warning message")
      before = floats()
      local top, bottom = false, false
      for win in pairs(before) do
        local position = vim.api.nvim_win_get_position(win)
        assert(position[2] > vim.o.columns / 3)
        top = top or position[1] < vim.o.lines / 2
        bottom = bottom or position[1] > vim.o.lines / 2
      end
      assert(top and bottom, "Both notification corners must be visible")
      vim.api.nvim_win_set_cursor(original_win, { 1, 0 })
      vim.api.nvim_feedkeys("i", "n", false)
    end)
    for index, char in ipairs({ "t", "y", "p", "i", "n", "g" }) do
      later(550 + index * 60, function()
        assert(vim.api.nvim_get_mode().mode:sub(1, 1) == "i", "Insert mode was interrupted")
        vim.api.nvim_feedkeys(char, "n", false)
      end)
    end
    later(1050, function()
      assert(vim.api.nvim_get_current_win() == original_win)
      assert(vim.api.nvim_buf_get_lines(original_buf, 0, 1, false)[1] == "typing")
      local after = floats()
      for win, buf in pairs(before) do
        assert(
          after[win] == buf,
          "An existing float was recreated while typing: " .. vim.inspect(tools.history())
        )
      end
      vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
      vim.api.nvim_exec_autocmds("User", {
        pattern = "CodeCompanionRequestFinished",
        data = { id = "tui", status = "success" },
      })
      assert(tools.tasks()[1].status == "success")
    end)
    later(1200, function()
      local text = capture()
      assert(text:find("Completed", 1, true))
      assert(vim.g.colors_name:find("catppuccin", 1, true))
      for _, item in ipairs(tools.history()) do
        assert(item.level ~= vim.log.levels.ERROR, item.message)
      end
      assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
      tools.dismiss(notice)
      vim.api.nvim_feedkeys(":let g:input_tools_config_value = '你好🙂'", "nt", false)
    end)
    later(1400, function()
      assert(vim.fn.getcmdline():find("你好🙂", 1, true))
      local visible = false
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        visible = visible or vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "input-tools-command"
      end
      assert(visible, "Configured command-line renderer is missing")
      assert(capture():find("你好🙂", 1, true))
      vim.api.nvim_feedkeys(vim.keycode("<CR>"), "nt", false)
    end)
    later(1600, function()
      assert(vim.g.input_tools_config_value == "你好🙂")
      vim.api.nvim_feedkeys(
        ":lua vim.g.input_tools_answer = vim.fn.input('Config input: ')" .. vim.keycode("<CR>"),
        "nt",
        false
      )
    end)
    later(1800, function()
      assert(capture():find("Config input:", 1, true))
      vim.api.nvim_feedkeys("answer" .. vim.keycode("<CR>"), "nt", false)
    end)
    later(2000, function()
      assert(vim.g.input_tools_answer == "answer")
      assert(require("input-tools").status().notifications)
      assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
      finish(
        true,
        "Terminal checks passed: configured notifications/input UI, native LSP/messages, API adapter, colors, continuous Insert input, Unicode command line and input()"
      )
    end)
  end,
})
