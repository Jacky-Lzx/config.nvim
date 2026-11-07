-- Full personal config, real terminal input and the native stdio Copilot client.
local done = false
local function finish(ok, message)
  if done then
    return
  end
  done = true
  local cmp = package.loaded["completion_tools"]
  if cmp then
    cmp.dispose()
  end
  vim.fn.writefile(vim.split(message, "\n", { plain = true }), vim.env.NVIM_STARTUP_RESULT)
  vim.cmd(ok and "qa!" or "cquit 1")
end
local function guarded(f)
  local ok, err = xpcall(f, debug.traceback)
  if not ok then
    finish(false, err)
  end
end
local function input(keys)
  vim.api.nvim_input(keys)
end
local function await(predicate, run)
  local deadline = vim.uv.hrtime() + 8e9
  local function poll()
    if done then
      return
    end
    guarded(function()
      if predicate() then
        run()
      elseif vim.uv.hrtime() > deadline then
        error("Copilot UI timeout at " .. debug.getinfo(predicate, "S").linedefined .. ": " .. vim.inspect({
          mode = vim.api.nvim_get_mode().mode,
          line = vim.api.nvim_get_current_line(),
          errors = _G.config_test_errors,
          status = require("completion_tools").get_status(),
        }))
      else
        vim.defer_fn(poll, 10)
      end
    end)
  end
  poll()
end
local function menu_footer()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "completion-tools-menu" then
      local footer = vim.api.nvim_win_get_config(win).footer
      if type(footer) == "string" then
        return footer
      end
      local chunks = {}
      for _, chunk in ipairs(footer or {}) do
        chunks[#chunks + 1] = chunk[1]
      end
      return table.concat(chunks)
    end
  end
  return ""
end
local function footer_screen()
  vim.cmd.redraw()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "completion-tools-menu" then
      local pos = vim.fn.screenpos(win, 1, 1)
      local wc = vim.api.nvim_win_get_config(win)
      local chars = {}
      for col = math.max(1, pos.col - 1), pos.col + wc.width do
        chars[#chars + 1] = vim.fn.screenstring(pos.row + wc.height, col)
      end
      return table.concat(chars)
    end
  end
  return ""
end
vim.api.nvim_create_autocmd("User", {
  pattern = "ConfigReady",
  once = true,
  callback = function()
    vim.defer_fn(function()
      guarded(function()
        local plugins = require("config.plugins").nodes()
        assert(not plugins["copilot.lua"])
        local previous_start = vim.lsp.start
        vim.lsp.start = function(config, ...)
          if config.name == "completion-tools-copilot" then
            return _G.config_test_real_lsp_start(config, ...)
          end
          return previous_start(config, ...)
        end
        local notify = vim.notify
        vim.notify = function() end
        vim.cmd("CompletionToolsCopilot status")
        vim.notify = notify
        assert(require("config.plugins").initialized("completion-tools.nvim"))
        local cmp = require("completion_tools")
        for _, client in ipairs(vim.lsp.get_clients()) do
          assert(client.name ~= "completion-tools-copilot", "Status started the server")
        end
        local opts = require("integrations.completion").options()
        local log = vim.env.NVIM_TEST_TMP .. "/copilot-protocol.jsonl"
        opts.copilot.command =
          { "python3", plugins["completion-tools.nvim"].dir .. "/tests/fixtures/copilot_server.py", log, "0.35" }
        opts.copilot.debounce_ms = 0
        local staged = vim.env.NVIM_TEST_COPILOT_MODE == "staged"
        if staged then
          opts.copilot.request_mode = "staged"
        end
        cmp.setup(opts)
        require("integrations.completion").setup()
        vim.cmd("edit " .. vim.fn.fnameescape(vim.env.NVIM_TEST_TMP .. "/native-copilot.lua"))
        vim.bo.filetype = "lua"
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "中😀 = )" })
        vim.api.nvim_win_set_cursor(0, { 1, #"中😀 = " })
        vim.b.completion_tools_sources = { "copilot" }
        local visible_frames = {}
        input("ipr")
        await(function()
          local screen = footer_screen()
          if screen:find("", 1, true) then
            for _, frame in ipairs({ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }) do
              if screen:find(frame, 1, true) then
                visible_frames[frame] = true
              end
            end
          end
          return #cmp.get_items() == 3 and vim.trim(menu_footer()) == ""
        end, function()
          assert(
            not staged or vim.tbl_count(visible_frames) >= 2,
            "Animated spinner was not painted in the terminal: " .. vim.inspect(visible_frames)
          )
          assert(cmp.get_selected_item().label == "print(1)")
          assert(not package.loaded["copilot.client"] and not package.loaded["copilot.api"])
          input("<A-i>")
          await(function()
            return not vim.tbl_contains(vim.b.completion_tools_sources, "copilot") and menu_footer() == ""
          end, function()
            input("<A-i>")
            await(function()
              return #cmp.get_items() == 3 and cmp.get_selected_item() and cmp.get_selected_item().label == "print(1)"
            end, function()
              input("<A-j>")
              await(function()
                return cmp.get_selected_item() and cmp.get_selected_item().label == "print(2)"
              end, function()
                input("<Tab>!<Esc>")
                await(function()
                  return vim.api.nvim_get_mode().mode == "n"
                    and vim.deep_equal(
                      vim.api.nvim_buf_get_lines(0, 0, -1, false),
                      { "中😀 = print(2)", 'print("done")!)' }
                    )
                end, function()
                  await(function()
                    for _, line in ipairs(vim.fn.readfile(log)) do
                      local m = vim.json.decode(line)
                      if m.method == "notifyAccepted" and m.params.uuid == "candidate-2" then
                        return true
                      end
                    end
                    return false
                  end, function()
                    local methods = {}
                    for _, line in ipairs(vim.fn.readfile(log)) do
                      local method = vim.json.decode(line).method
                      if method then
                        methods[method] = true
                      end
                    end
                    assert(methods.getCompletionsCycling, "Missing real cycling request")
                    assert(not not methods.getCompletions == staged, "Request mode did not match selected policy")
                    assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
                    finish(
                      true,
                      "Configured native Copilot: cold status, Alt-i off/on, selected request mode, menu status, three candidates, Alt-j, multiline Tab and following input passed"
                    )
                  end)
                end)
              end)
            end)
          end)
        end)
      end)
    end, 50)
  end,
})
