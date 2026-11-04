-- Uses actual terminal input from tests/tui.py against the full configuration.
local directory = assert(vim.env.NVIM_TEST_TMP)
local result = assert(vim.env.NVIM_LAZY_RESULT)
local api = vim.api
local stage, ticks, finished = "startup", 0, false
local origin, picker, visual_picker, previous_wrap
local latest_picker
local function mark(value)
  vim.fn.writefile({ value }, directory .. "/keymap-stage")
end
local function check_owners()
  local plugins = require("lazy.core.config").plugins
  assert(plugins["keymap-tools.nvim"]._.loaded, "keymap-tools did not load at startup")
  assert(plugins["selection-tools.nvim"]._.loaded, "selection-tools missing")
  assert(plugins["keymap-tools.nvim"].dir == require("utils.platform").dev_plugin_root() .. "/keymap-tools.nvim")
  assert(not plugins["which-key.nvim"] and not package.loaded["which-key"], "legacy hint owner remains")
  assert(
    vim.iter(require("keymap_tools").list({ mode = "o", prefix = "if", kinds = { "hint" } })):any(function(item)
      return item.keys == "if" and item.source == "mini.ai"
    end),
    "cold mini.ai descriptions missing"
  )
  for _, mode in ipairs({ "n", "x" }) do
    local map = vim.fn.maparg(" ?", mode, false, true)
    assert(map.desc == "Choose and execute buffer keymap", "old picker binding remains")
    for _, entry in ipairs(api.nvim_buf_get_keymap(0, mode)) do
      assert(not (entry.desc or ""):find("which-key-trigger", 1, true), "which-key installed a competing trigger")
    end
  end
end
local timer = vim.uv.new_timer()
timer:start(
  25,
  25,
  vim.schedule_wrap(function()
    if finished then
      return
    end
    local ok, err = xpcall(function()
      ticks = ticks + 1
      assert(ticks < 900, "keymap installation TUI timed out at " .. stage)
      local view = package.loaded["keymap_tools.view"]
      if stage == "startup" and vim.g.did_very_lazy then
        check_owners()
        vim.cmd("enew!")
        api.nvim_buf_set_lines(0, 0, -1, false, { "first line", "second line" })
        origin = api.nvim_get_current_win()
        previous_wrap = vim.wo.wrap
        local selection = require("selection_tools")
        local select_items = selection.select
        selection.select = function(...)
          latest_picker = select_items(...)
          return latest_picker
        end
        mark("prefix")
        stage = "hint"
      elseif stage == "hint" and view and view.win then
        local pos = vim.fn.win_screenpos(view.win)
        local cfg = api.nvim_win_get_config(view.win)
        assert(pos[1] > 10 and pos[2] > 50, "hint is not at the bottom right")
        assert(cfg.anchor == "SE" and not cfg.focusable)
        assert(not package.loaded["which-key"], "legacy hint owner loaded")
        mark("subgroup")
        stage = "selection_hint"
      elseif stage == "selection_hint" and view and view.buf then
        local text = table.concat(api.nvim_buf_get_lines(view.buf, 0, -1, false), "\n")
        if not text:find("[Selection]", 1, true) then
          return
        end
        mark("hint_cancel")
        stage = "open_picker"
      elseif stage == "open_picker" and not view.win then
        mark("picker")
        stage = "filter"
      elseif stage == "filter" and latest_picker and api.nvim_get_mode().mode == "i" then
        picker = latest_picker
        mark("filter")
        stage = "confirm"
      elseif stage == "confirm" and picker.query == "Wrap" then
        assert(#picker.matches == 1)
        assert(picker:current().keys == " tw", "wrong real mapping selected")
        mark("confirm")
        stage = "executed"
      elseif stage == "executed" and picker.closed and vim.wo.wrap ~= previous_wrap then
        assert(api.nvim_get_current_win() == origin and api.nvim_get_mode().mode == "n")
        local description
        for _, item in ipairs(require("keymap_tools").list({ mode = "n", kinds = { "mapping" } })) do
          if item.keys == "<Space>tw" then
            description = item.desc
          end
        end
        assert(description == (vim.wo.wrap and "Disable " or "Enable ") .. "Wrap", "toggle description is stale")
        mark("visual_picker")
        stage = "visual_cancel"
      elseif stage == "visual_cancel" and latest_picker ~= picker and api.nvim_get_mode().mode == "i" then
        visual_picker = latest_picker
        assert(visual_picker.opts.prompt:match("x$"), "Visual picker used wrong mapping mode")
        mark("visual_cancel")
        stage = "visual_restored"
      elseif stage == "visual_restored" and visual_picker.closed and require("keymap_tools.keys").mode() == "x" then
        assert(vim.fn.line("v") == 1 and vim.fn.line(".") == 2, "Visual cancellation lost range")
        mark("visual_escape")
        stage = "operator"
      elseif stage == "operator" and api.nvim_get_mode().mode == "n" then
        -- mini.ai still handles selection; keymap-tools owns the waiting hints.
        api.nvim_buf_set_lines(0, 0, -1, false, { "one (inner words) tail" })
        api.nvim_win_set_cursor(origin, { 1, 6 })
        mark("operator_prefix")
        stage = "operator_hint"
      elseif stage == "operator_hint" and view and view.win and require("keymap_tools.hints").session.mode == "o" then
        mark("object_prefix")
        stage = "object_hint"
      elseif stage == "object_hint" and view and view.frame and view.frame.prefix == "i" then
        mark("object_apply")
        stage = "operator_done"
      elseif stage == "operator_done" and api.nvim_get_current_line() == "one () tail" then
        assert(package.loaded["mini.ai"], "mini.ai failed on first use")
        vim.fn.setreg("z", "CONFIG")
        api.nvim_buf_set_lines(0, 0, -1, false, { "x" })
        api.nvim_win_set_cursor(0, { 1, 0 })
        mark("insert_register")
        stage = "insert_hint"
      elseif stage == "insert_hint" and view and view.frame and view.frame.prefix == vim.keycode("<C-r>") then
        assert(api.nvim_get_mode().mode == "i")
        mark("insert_register_apply")
        stage = "insert_applied"
      elseif stage == "insert_applied" and api.nvim_get_current_line() == "CONFIGx" then
        mark("leave_insert")
        stage = "command_register"
      elseif stage == "command_register" and api.nvim_get_mode().mode == "n" then
        mark("command_register")
        stage = "command_hint"
      elseif stage == "command_hint" and view and view.frame and view.frame.prefix == vim.keycode("<C-r>") then
        assert(api.nvim_get_mode().mode == "c")
        mark("command_register_apply")
        stage = "command_applied"
      elseif stage == "command_applied" and vim.fn.getcmdline() == "CONFIG" then
        mark("command_cancel")
        stage = "done"
      elseif stage == "done" and api.nvim_get_mode().mode == "n" then
        assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
        finished = true
        timer:stop()
        timer:close()
        vim.fn.writefile({
          "PASS configured startup without which-key, bottom-right hints, executable picker, dynamic Wrap descriptions, Visual cancellation, cold mini.ai operator hints, and Insert/command-line register hints with the existing input UI",
        }, result)
        vim.cmd("qa!")
      end
    end, debug.traceback)
    if not ok then
      finished = true
      timer:stop()
      timer:close()
      vim.fn.writefile(vim.split(err, "\n", { plain = true }), result)
      vim.cmd("cquit 1")
    end
  end)
)
