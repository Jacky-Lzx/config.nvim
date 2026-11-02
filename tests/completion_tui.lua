local result = assert(vim.env.NVIM_LAZY_RESULT)
local done = false
local events = {}
vim.api.nvim_create_autocmd({ "TextChangedI", "CursorMovedI" }, {
  callback = function(args)
    events[#events + 1] =
      { event = args.event, line = vim.api.nvim_get_current_line(), cursor = vim.api.nvim_win_get_cursor(0) }
  end,
})
local function finish(ok, message)
  if done then
    return
  end
  done = true
  vim.fn.writefile(vim.split(message, "\n", { plain = true }), result)
  vim.cmd(ok and "qa!" or "cquit 1")
end
local function later(run)
  vim.defer_fn(function()
    if done then
      return
    end
    local ok, err = xpcall(run, debug.traceback)
    if not ok then
      finish(false, err)
    end
  end, 20)
end
local function await(check, run, deadline)
  deadline = deadline or (vim.uv.now() + 3000)
  later(function()
    if check() then
      run()
    else
      assert(
        vim.uv.now() < deadline,
        "Completion input check timed out at "
          .. debug.getinfo(check, "S").linedefined
          .. ": "
          .. vim.inspect({
            line = vim.api.nvim_get_current_line(),
            cursor = vim.api.nvim_win_get_cursor(0),
            events = events,
            mode = vim.api.nvim_get_mode().mode,
            context = package.loaded["completion-tools"] and require("completion-tools").get_context(),
            errors = _G.config_test_errors,
          })
      )
      await(check, run, deadline)
    end
  end)
end
local function input(keys)
  vim.api.nvim_input(keys)
end
local function buffer()
  vim.cmd("enew!")
  vim.bo.filetype = "lua"
  vim.bo.autoindent, vim.bo.expandtab, vim.bo.shiftwidth = true, true, 2
  vim.bo.indentexpr = ""
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "alpha alphabet alphanumeric", "" })
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  vim.b.completion_tools_sources = { "buffer" }
end
local function visible()
  local cmp = package.loaded["completion-tools"]
  local ctx = cmp and cmp.get_context()
  return ctx and ctx.prefix == "al" and cmp.is_menu_visible() and cmp._can("accept")
end
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    later(function()
      assert(not require("lazy.core.config").plugins["blink.cmp"])
      buffer()
      input("ial")
      await(visible, function()
        local cmp = require("completion-tools")
        assert(cmp.get_selected_item().label == "alpha")
        local menu_line
        for _, w in ipairs(vim.api.nvim_list_wins()) do
          local b = vim.api.nvim_win_get_buf(w)
          if vim.bo[b].filetype == "completion-tools-menu" then
            menu_line = vim.api.nvim_buf_get_lines(b, 0, 1, false)[1]
          end
        end
        assert(menu_line and menu_line:find("alpha", 1, true) and menu_line:find("Text", 1, true), menu_line)
        assert(not package.loaded["colorful-menu"])
        local plugin = require("lazy.core.config").plugins["completion-tools.nvim"]
        assert(
          plugin._.is_local
            and plugin.dir == vim.fs.joinpath(require("utils.platform").dev_plugin_root(), "completion-tools.nvim")
        )
        input("<C-n><Tab>!")
        await(function()
          return vim.api.nvim_get_current_line() == "alphabet!"
        end, function()
          input("<Esc>")
          await(function()
            return vim.api.nvim_get_mode().mode == "n"
          end, function()
            buffer()
            input("ial")
            await(visible, function()
              input("<CR>!")
              await(function()
                return vim.api.nvim_get_current_line() == "alpha!"
              end, function()
                assert(vim.api.nvim_buf_line_count(0) == 2, "Accepting Enter inserted a newline")
                input("<Esc>")
                await(function()
                  return vim.api.nvim_get_mode().mode == "n"
                end, function()
                  vim.cmd("enew!")
                  vim.bo.filetype = "lua"
                  vim.bo.autoindent, vim.bo.expandtab, vim.bo.shiftwidth = true, true, 2
                  vim.bo.indentexpr = ""
                  input("i(<CR>x")
                  await(function()
                    return vim.api.nvim_get_current_line() == "  x"
                  end, function()
                    assert(
                      vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "(", "  x", ")" }),
                      "Enter must delegate to pairs"
                    )
                    assert(not package.loaded["blink.cmp"])
                    assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
                    finish(
                      true,
                      "Configured completion: local plugin, kind columns, independent highlights, Ctrl-N/Tab/Enter acceptance and pairs newline passed"
                    )
                  end)
                end)
              end)
            end)
          end)
        end)
      end)
    end)
  end,
})
