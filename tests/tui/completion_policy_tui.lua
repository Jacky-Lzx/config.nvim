local api = vim.api
local result = assert(vim.env.NVIM_STARTUP_RESULT)
local finished = false
local function finish(ok, message)
  if finished then
    return
  end
  finished = true
  vim.fn.writefile(vim.split(message, "\n", { plain = true }), result)
  vim.cmd(ok and "qa!" or "cquit 1")
end
local function await(predicate, callback)
  local deadline = vim.uv.hrtime() + 5e9
  local function poll()
    local ok, err = xpcall(function()
      if predicate() then
        callback()
      else
        assert(
          vim.uv.hrtime() < deadline,
          "Completion policy timed out at "
            .. debug.getinfo(predicate, "S").linedefined
            .. ": "
            .. vim.inspect({
              line = api.nvim_get_current_line(),
              mode = api.nvim_get_mode().mode,
              status = package.loaded.completion_tools and package.loaded.completion_tools.get_status(),
              context = package.loaded.completion_tools and package.loaded.completion_tools.get_context(),
            })
        )
        vim.defer_fn(poll, 5)
      end
    end, debug.traceback)
    if not ok then
      finish(false, err)
    end
  end
  vim.schedule(poll)
end
local function candidate()
  local cmp = package.loaded.completion_tools
  if cmp and cmp.is_menu_visible() then
    for _, item in ipairs(cmp.get_items()) do
      if item.label == "aardvark" then
        return true
      end
    end
  end
  return false
end
local function rendered()
  for row = 1, vim.o.lines do
    local line = {}
    for col = 1, vim.o.columns do
      line[#line + 1] = vim.fn.screenstring(row, col)
    end
    if table.concat(line):find("aardvark", 1, true) then
      return true
    end
  end
  return false
end
api.nvim_create_autocmd("User", {
  pattern = "ConfigReady",
  once = true,
  callback = function()
    local ok, err = xpcall(function()
      vim.cmd.edit(vim.env.NVIM_TEST_TMP .. "/sample.tex")
      vim.bo.filetype = "tex"
      api.nvim_buf_set_lines(0, 0, -1, false, {
        "\\documentclass{article}",
        "\\begin{document}",
        "aard",
        "$aard$",
        "\\end{document}",
      })
      api.nvim_win_set_cursor(0, { 3, 3 })
      api.nvim_input("Av")
      await(candidate, function()
        vim.cmd.redraw()
        assert(rendered(), "Prose dictionary result did not render")
        api.nvim_input("<Esc>")
        await(function()
          return api.nvim_get_mode().mode == "n"
        end, function()
          api.nvim_win_set_cursor(0, { 4, 5 })
          api.nvim_input("iv")
          await(function()
            local cmp = require("completion_tools")
            local ctx = cmp.get_context()
            return ctx and ctx.row == 3 and ctx.prefix == "aardv"
          end, function()
            local cmp = require("completion_tools")
            assert(require("tex-tools").in_math(), "Expected a real parsed math context")
            local sources = require("integrations.completion").options().sources(cmp.get_context())
            assert(not vim.list_contains(sources, "dictionary") and not vim.list_contains(sources, "spell"))
            assert(not candidate(), "Dictionary leaked into automatic math completion")
            api.nvim_input("<A-n>")
            await(candidate, function()
              vim.cmd.redraw()
              assert(rendered(), "Manual word source did not render inside math")
              assert(api.nvim_get_mode().mode:sub(1, 1) == "i")
              assert(api.nvim_get_current_line() == "$aardv$", "Source switching changed the formula")
              assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
              finish(
                true,
                "PTY completion policy: prose dictionary, parsed TeX math exclusion, manual override, rendered menu and cursor mode passed"
              )
            end)
          end)
        end)
      end)
    end, debug.traceback)
    if not ok then
      finish(false, err)
    end
  end,
})
