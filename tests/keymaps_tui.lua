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
  local triggers = require("which-key.config").triggers
  assert(triggers.modes.o and not triggers.modes.n and not triggers.modes.x, "overlapping hint owners")
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
        assert(not require("which-key.state").state, "two hints opened at once")
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
      elseif stage == "confirm" and picker.query == "Toggle Wrap" then
        assert(#picker.matches == 1)
        assert(picker:current().keys == " tw", "wrong real mapping selected")
        mark("confirm")
        stage = "executed"
      elseif stage == "executed" and picker.closed and vim.wo.wrap ~= previous_wrap then
        assert(api.nvim_get_current_win() == origin and api.nvim_get_mode().mode == "n")
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
        -- The existing mini.ai/which-key integration still handles textobjects.
        api.nvim_buf_set_lines(0, 0, -1, false, { "one (inner words) tail" })
        api.nvim_win_set_cursor(origin, { 1, 6 })
        mark("textobject")
        stage = "operator_done"
      elseif stage == "operator_done" and api.nvim_get_current_line() == "one () tail" then
        assert(package.loaded["mini.ai"], "mini.ai failed on first use")
        assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
        finished = true
        timer:stop()
        timer:close()
        vim.fn.writefile({
          "PASS configured startup, exclusive hint ownership, bottom-right groups, <leader>? search/execute real Wrap toggle, Visual cancellation and existing mini.ai textobjects",
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
