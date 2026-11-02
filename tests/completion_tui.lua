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
local function commandline_completion()
  input("<Esc>")
  await(function()
    return vim.api.nvim_get_mode().mode == "n"
  end, function()
    input(":")
    await(function()
      return vim.api.nvim_get_mode().mode == "c" and require("input-tools").get_layout() ~= nil
    end, function()
      local cmp = require("completion-tools")
      assert(not cmp.is_menu_visible(), "Empty command line opened completion")
      input("set nu")
      await(function()
        return cmp.is_menu_visible()
      end, function()
        assert(vim.fn.getcmdline() == "set nu")
        input("<C-n><A-k><Tab>")
        await(function()
          local box = require("input-tools").get_layout()
          return vim.fn.getcmdline() == "set number"
            and box ~= nil
            and table.concat(vim.api.nvim_buf_get_lines(box.buf, 0, -1, false), "\n"):find("set number", 1, true)
              ~= nil
        end, function()
          assert(vim.api.nvim_get_mode().mode == "c", "Accepting Tab executed the command")
          input("<Esc>")
          await(function()
            return vim.api.nvim_get_mode().mode == "n"
          end, function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "thematic" })
            input("/them")
            await(function()
              return cmp.is_menu_visible() and cmp.get_selected_item().label == "thematic"
            end, function()
              input("<Tab><CR>")
              await(function()
                return vim.api.nvim_get_mode().mode == "n" and vim.fn.getreg("/") == "thematic"
              end, function()
                assert(not cmp.is_menu_visible())
                assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
                finish(
                  true,
                  "Configured completion: insert, dictionary/spell, external command-line navigation/acceptance and search passed"
                )
              end)
            end)
          end)
        end)
      end)
    end)
  end)
end
local function word_sources()
  input("<Esc>")
  await(function()
    return vim.api.nvim_get_mode().mode == "n"
  end, function()
    vim.cmd("enew!")
    vim.b.completion_tools_sources = { "dictionary" }
    input("iaardv")
    await(function()
      local item = require("completion-tools").get_selected_item()
      return item and item.label == "aardvark"
    end, function()
      input("<Tab>!")
      await(function()
        return vim.api.nvim_get_current_line() == "aardvark!"
      end, function()
        input("<Esc>")
        await(function()
          return vim.api.nvim_get_mode().mode == "n"
        end, function()
          vim.cmd("enew!")
          vim.wo.spell = true
          vim.bo.spelllang = "en"
          vim.b.completion_tools_sources = { "spell" }
          input("iteh")
          await(function()
            for _, item in ipairs(require("completion-tools").get_items()) do
              if item.label == "the" then
                return true
              end
            end
            return false
          end, function()
            local cmp = require("completion-tools")
            for _ = 1, #cmp.get_items() do
              if cmp.get_selected_item().label == "the" then
                break
              end
              cmp.select_next()
            end
            input("<Tab>!")
            await(function()
              return vim.api.nvim_get_current_line() == "the!"
            end, function()
              vim.wo.spell = false
              assert(not package.loaded["blink-cmp-dictionary"] and not package.loaded["blink-cmp-spell"])
              assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
              commandline_completion()
            end)
          end)
        end)
      end)
    end)
  end)
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
        assert(
          menu_line
            and menu_line:find("alpha", 1, true)
            and menu_line:find("Text", 1, true)
            and menu_line:find("Buffer", 1, true),
          menu_line
        )
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
                    word_sources()
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
