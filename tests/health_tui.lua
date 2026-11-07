-- Run through tests/tui.py: physical command input and rendered health frames.
local api = vim.api
local directory = assert(vim.env.NVIM_TEST_TMP)
local stage, source, contents, cold = "startup", nil, nil, {}
local timer = assert(vim.uv.new_timer())
local ticks = 0
local function input(name, keys)
  stage = name
  vim.fn.writefile({ name, vim.json.encode(keys) }, directory .. "/health-stage")
end
local function finish(ok, err)
  timer:stop()
  timer:close()
  vim.fn.writefile(
    { ok and "PASS health/Info TUI: compact reports, cold providers, source preservation and native close" or err },
    vim.env.NVIM_STARTUP_RESULT
  )
  vim.cmd(ok and "qa!" or "cquit 1")
end
timer:start(
  25,
  25,
  vim.schedule_wrap(function()
    local ok, err = xpcall(function()
      ticks = ticks + 1
      assert(ticks < 500, "Health TUI timed out at " .. stage)
      if stage == "startup" then
        if not vim.g.config_ready then
          return
        end
        vim.cmd.edit(directory .. "/health-source.txt")
        api.nvim_buf_set_lines(0, 0, -1, false, { "health 源文件", "unchanged" })
        source = api.nvim_get_current_buf()
        contents = api.nvim_buf_get_lines(source, 0, -1, false)
        for _, name in ipairs({
          "dap",
          "dap_tools.ui",
          "image_tools.runtime",

          "selection_tools.picker",
        }) do
          cold[name] = package.loaded[name] or false
        end
        input(
          "health",
          ":checkhealth config plugin_tools completion_tools image_tools lsp-tools pairs keymap_tools input-tools notification-tools<CR>"
        )
      elseif stage == "health" and vim.bo.filetype == "checkhealth" then
        local text = table.concat(api.nvim_buf_get_lines(0, 0, -1, false), "\n")
        if not text:find("Notification runtime requirements", 1, true) then
          return
        end
        assert(text:find("Neovim configuration", 1, true) and text:find("Details: :ConfigInfo", 1, true))
        for _, noise in ipairs({ "Pure Lua", "Platform:", "Current usage:", "Engine state:", "Enabled LSP servers:" }) do
          assert(not text:find(noise, 1, true), noise)
        end
        assert(not text:find("Failed to run healthcheck", 1, true), text)
        for name, previous in pairs(cold) do
          assert((package.loaded[name] or false) == previous, "Health loaded " .. name)
        end
        api.nvim_win_set_cursor(0, { 1, 0 })
        vim.cmd.redraw()
        stage = "frame"
      elseif stage == "frame" then
        local rows = {}
        for row = 1, vim.o.lines do
          local cells = {}
          for col = 1, vim.o.columns do
            cells[#cells + 1] = vim.fn.screenstring(row, col)
          end
          rows[#rows + 1] = table.concat(cells)
        end
        local screen = table.concat(rows, "\n")
        assert(screen:find("Neovim configuration", 1, true), "Health title did not render")
        assert(screen:find("Details: :ConfigInfo", 1, true), "Details link did not render")
        vim.fn.writefile(rows, directory .. "/health-rendered.txt")
        input("close", "q")
      elseif stage == "close" and api.nvim_get_current_buf() == source then
        assert(vim.deep_equal(contents, api.nvim_buf_get_lines(source, 0, -1, false)))
        assert(vim.api.nvim_get_mode().mode == "n")
        assert(vim.fn.exists(":PairsInfo") == 2 and vim.fn.exists(":InputToolsInfo") == 2)
        assert(vim.fn.exists(":NotificationToolsInfo") == 2)
        input("info", ":PairsInfo<CR>:InputToolsInfo<CR>:lua vim.g.health_info_checked = true<CR>")
      elseif stage == "info" and vim.g.health_info_checked and vim.api.nvim_get_mode().mode == "n" then
        assert(api.nvim_get_current_buf() == source)
        assert(vim.deep_equal(contents, api.nvim_buf_get_lines(source, 0, -1, false)))
        for name, previous in pairs(cold) do
          assert((package.loaded[name] or false) == previous, "Info loaded " .. name)
        end
        finish(true)
      end
    end, debug.traceback)
    if not ok then
      finish(false, err)
    end
  end)
)
