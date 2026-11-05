-- Uses actual terminal input from tests/tui.py against the full configuration.
local directory = assert(vim.env.NVIM_TEST_TMP)
local result = assert(vim.env.NVIM_STARTUP_RESULT)
local api = vim.api
local stage, ticks, finished = "startup", 0, false
if vim.v.vim_did_enter == 0 then
  for _, name in ipairs({ "keymap_tools.hints", "keymap_tools.view", "keymap_tools.picker" }) do
    assert(not package.loaded[name], name .. " loaded before VimEnter")
  end
end
local origin, picker, visual_picker, previous_wrap
local latest_picker
local function mark(value)
  vim.fn.writefile({ value }, directory .. "/keymap-stage")
end
local function check_owners()
  local plugins = require("config.plugins").nodes()
  assert(require("config.plugins").initialized("keymap-tools.nvim"), "keymap-tools did not load at startup")
  assert(not plugins.showkeys and not package.loaded.showkeys, "Legacy screencast owner remains")
  assert(vim.fn.exists(":ShowkeysToggle") == 0)
  assert(not require("keymap_tools").showkeys.is_enabled())
  assert(not package.loaded["keymap_tools.showkeys"], "Screencast loaded before being enabled")
  assert(require("keymap_tools.config").get().showkeys.maxkeys == 5)
  assert(require("config.plugins").initialized("selection-tools.nvim"), "selection-tools missing")
  assert(plugins["keymap-tools.nvim"].dir == require("utils.platform").dev_plugin_root() .. "/keymap-tools.nvim")
  assert(not plugins["which-key.nvim"] and not package.loaded["which-key"], "legacy hint owner remains")
  assert(
    vim.iter(require("keymap_tools").list({ mode = "o", prefix = "if", kinds = { "hint" } })):any(function(item)
      return item.keys == "if" and item.source == "editing-tools.nvim"
    end),
    "cold editing-tools.nvim descriptions missing"
  )
  local tools = require("keymap_tools")
  local rows, info = tools.list({ mode = "n", prefix = "<leader>t" })
  assert(#info.errors == 0, vim.inspect(info.errors))
  local by_key = {}
  for _, row in ipairs(rows) do
    by_key[row.keys] = row
  end
  for _, key in ipairs({
    "td",
    "tV",
    "tv",
    "tf",
    "tw",
    "ts",
    "tL",
    "tl",
    "tc",
    "tb",
    "th",
    "ta",
    "tS",
    "tT",
    "tPp",
    "tPh",
    "tG",
    "tD",
    "tp",
    "tgb",
    "tgw",
    "tgs",
    "to",
  }) do
    assert(by_key["<Space>" .. key] and by_key["<Space>" .. key].toggle, "Missing toggle metadata: " .. key)
  end
  assert(require("config.plugins").initialized("conform.nvim"), "Status reads loaded the formatter")
  assert(require("config.plugins").initialized("pairs.nvim"), "Status reads loaded pairing")
  assert(by_key["<Space>tp"].toggle.state == require("pairs").status().enabled, "Pairing status is stale")
  local image_loaded = package.loaded.image_tools
  local image
  for _, item in ipairs(tools.list({ mode = "n", prefix = "<leader>ui" })) do
    image = item
  end
  assert(image and image.toggle.name == "Automatic image preview" and image.toggle.state == true)
  assert(package.loaded.image_tools == image_loaded, "Status reads loaded image-tools")
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
      if stage == "startup" and vim.g.config_ready then
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
        vim.cmd("KeymapTools showkeys enable")
        assert(require("keymap_tools").showkeys.is_enabled())
        mark("prefix")
        stage = "hint"
      elseif stage == "hint" and view and view.win then
        local cast = require("keymap_tools.showkeys")
        if not cast.win then
          return
        end
        vim.cmd.redraw()
        assert(api.nvim_buf_get_lines(cast.buf, 0, 1, false)[1] == " ␣ ", "Screencast lost the typed prefix")
        assert(vim.fn.win_screenpos(cast.win)[1] + 2 < vim.fn.win_screenpos(view.win)[1], "Screencast covers hints")
        assert(api.nvim_get_current_win() == origin, "Screencast stole editor focus")
        local pos = vim.fn.win_screenpos(view.win)
        local cfg = api.nvim_win_get_config(view.win)
        assert(pos[1] > 10 and pos[2] + cfg.width + 1 == vim.o.columns - 1, "hint is not at the bottom right")
        assert(view.frame.columns == 2, "configured hints should use two columns")
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
      elseif stage == "confirm" and picker.query == "tw Wrap" then
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
            assert(item.toggle.name == "Wrap" and item.toggle.state == vim.wo.wrap)
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
        -- editing-tools.nvim still handles selection; keymap-tools owns the waiting hints.
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
        assert(package.loaded["editing_tools"], "editing-tools.nvim failed on first use")
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
        vim.cmd("KeymapTools showkeys")
        assert(not require("keymap_tools").showkeys.is_enabled())
        local cast = require("keymap_tools.showkeys")
        assert(not cast.win and not cast.buf, "Disabling screencast leaked its UI")
        assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
        finished = true
        timer:stop()
        timer:close()
        vim.fn.writefile({
          "PASS configured startup without which-key/showkeys, opt-in screencast rendering and cleanup, bottom-right hints, executable picker, dynamic Wrap descriptions, Visual cancellation, cold editing-tools.nvim operator hints, and Insert/command-line register hints with the existing input UI",
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
