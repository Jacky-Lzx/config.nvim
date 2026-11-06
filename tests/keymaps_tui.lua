-- Uses actual terminal input from tests/tui.py against the full configuration.
local directory = assert(vim.env.NVIM_TEST_TMP)
local result = assert(vim.env.NVIM_STARTUP_RESULT)
local api = vim.api
local actions = dofile(vim.env.NVIM_CONFIG_ROOT .. "/tests/actions.lua")
local wrap_keys, wrap_query
local stage, ticks, finished = "startup", 0, false
if vim.v.vim_did_enter == 0 then
  for _, name in ipairs({ "keymap_tools.hints", "keymap_tools.view", "keymap_tools.picker" }) do
    assert(not package.loaded[name], name .. " loaded before VimEnter")
  end
end
local origin, picker, visual_picker, previous_wrap, dashboard_buf, dashboard_picker
local latest_picker
local insert_hits = 0
local function mark(value, input)
  local lines = { value }
  if input then
    lines[2] = vim.json.encode(input)
  end
  vim.fn.writefile(lines, directory .. "/keymap-stage")
end
local function check_owners()
  local plugins = require("config.plugins").nodes()
  assert(require("config.plugins").initialized("keymap-tools.nvim"), "keymap-tools did not load at startup")
  assert(not plugins.showkeys and not package.loaded.showkeys, "Legacy screencast owner remains")
  assert(vim.fn.exists(":ShowkeysToggle") == 0)
  assert(not require("keymap_tools").showkeys.is_enabled())
  assert(not package.loaded["keymap_tools.showkeys"], "Screencast loaded before being enabled")
  assert(require("keymap_tools.config").get().showkeys.maxkeys == plugins["keymap-tools.nvim"].opts.showkeys.maxkeys)
  assert(require("config.plugins").initialized("selection-tools.nvim"), "selection-tools missing")
  assert(plugins["keymap-tools.nvim"].dir == require("utils.platform").dev_plugin_root() .. "/keymap-tools.nvim")
  assert(not plugins["which-key.nvim"] and not package.loaded["which-key"], "legacy hint owner remains")
  assert(
    vim.iter(require("keymap_tools").list({ mode = "o", prefix = "if", kinds = { "hint" } })):any(function(item)
      return item.keys == "if" and item.source == "motion-tools.nvim"
    end),
    "cold motion-tools.nvim descriptions missing"
  )
  -- Both daily entry points share mode restoration and effective-map execution.
  local owner = require("keymap_tools")
  local pick, hits = owner.pick, 0
  owner.pick = function()
    hits = hits + 1
  end
  vim.fn.maparg("<leader>sk", "n", false, true).callback()
  vim.fn.maparg(actions.binding("keymaps.pick").lhs, "n", false, true).callback()
  owner.pick = pick
  assert(hits == 2, "Configured keymap entry points diverged")
  local tools = require("keymap_tools")
  local rows, info = tools.list({ mode = "n" })
  assert(#info.errors == 0, vim.inspect(info.errors))
  wrap_keys = actions.keys("toggle.wrap")
  local wrap
  for _, row in ipairs(rows) do
    if vim.keycode(row.keys) == wrap_keys then
      wrap = row
    end
  end
  assert(wrap and wrap.toggle and wrap.toggle.state == vim.wo.wrap, "Missing configured Wrap state")
  wrap_query = require("keymap_tools.keys").display(wrap_keys) .. " Wrap"
  assert(require("config.plugins").initialized("format-tools.nvim"), "Status reads loaded the formatter")
  assert(require("config.plugins").initialized("pairs.nvim"), "Status reads loaded pairing")
  local image_loaded = package.loaded.image_tools
  local image
  for _, item in ipairs(tools.list({ mode = "n", prefix = "<leader>ui" })) do
    image = item
  end
  assert(image and image.toggle.name == "Automatic image preview" and image.toggle.state == true)
  assert(package.loaded.image_tools == image_loaded, "Status reads loaded image-tools")
  for _, mode in ipairs({ "n", "x" }) do
    local map = vim.fn.maparg(actions.binding("keymaps.pick", mode).lhs, mode, false, true)
    assert(map.desc == "Choose and execute buffer keymap", "old picker binding remains")
    for _, entry in ipairs(api.nvim_buf_get_keymap(0, mode)) do
      assert(not (entry.desc or ""):find("which-key-trigger", 1, true), "which-key installed a competing trigger")
    end
  end
  for _, mode in ipairs({ "n", "x", "i" }) do
    actions.binding("keymaps.pick.universal", mode)
    actions.binding("keymaps.pick.legacy", mode)
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
        local selection = require("selection_tools")
        local select_items = selection.select
        selection.select = function(...)
          latest_picker = select_items(...)
          return latest_picker
        end
        require("ui_tools.dashboard").open()
        dashboard_buf = api.nvim_get_current_buf()
        require("keymap_tools").refresh()
        mark("dashboard_prefix", " ")
        stage = "dashboard_hint"
      elseif stage == "dashboard_hint" and view and view.win then
        assert(api.nvim_get_current_buf() == dashboard_buf, "Dashboard hint stole focus")
        assert(require("keymap_tools.hints").session.prefix == "<Space>")
        vim.cmd.redraw()
        local text = table.concat(api.nvim_buf_get_lines(view.buf, 0, -1, false), "\n")
        assert(text:find("Selection", 1, true), "Dashboard hint did not render leader actions")
        mark("dashboard_search", actions.input("keymaps.pick"):sub(#vim.g.mapleader + 1))
        stage = "dashboard_picker"
      elseif stage == "dashboard_picker" and latest_picker and api.nvim_get_mode().mode == "i" then
        dashboard_picker = latest_picker
        assert(dashboard_picker.opts.prompt:match("n$"), "Dashboard picker used the wrong mode")
        mark("dashboard_cancel", "\27")
        stage = "dashboard_burst"
      elseif stage == "dashboard_burst" and dashboard_picker.closed then
        assert(api.nvim_get_current_buf() == dashboard_buf, "Picker cancellation lost dashboard")
        assert(api.nvim_get_mode().mode == "n", "Dashboard mode was not restored")
        mark("dashboard_fast_search", actions.input("keymaps.pick"))
        stage = "dashboard_fast_picker"
      elseif stage == "dashboard_fast_picker" and latest_picker ~= dashboard_picker then
        dashboard_picker = latest_picker
        mark("dashboard_fast_cancel", "\27")
        stage = "editor_setup"
      elseif stage == "editor_setup" and dashboard_picker.closed then
        assert(api.nvim_get_current_buf() == dashboard_buf)
        require("ui_tools.dashboard").close()
        vim.cmd("enew!")
        api.nvim_buf_set_lines(0, 0, -1, false, { "first line", "second line" })
        origin = api.nvim_get_current_win()
        previous_wrap = vim.wo.wrap
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
        assert(view.frame.columns >= 1 and cfg.width <= vim.o.columns, "Hint layout exceeds the terminal")
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
        mark("picker", actions.input("keymaps.pick"))
        stage = "filter"
      elseif stage == "filter" and latest_picker and api.nvim_get_mode().mode == "i" then
        picker = latest_picker
        mark("filter", wrap_query)
        stage = "confirm"
      elseif stage == "confirm" and picker.query == wrap_query and not picker.matching then
        assert(#picker.matches == 1, vim.inspect({ query = picker.query, matches = picker.matches }))
        assert(picker:current().keys == wrap_keys, "wrong real mapping selected")
        mark("confirm")
        stage = "executed"
      elseif stage == "executed" and picker.closed and vim.wo.wrap ~= previous_wrap then
        assert(api.nvim_get_current_win() == origin and api.nvim_get_mode().mode == "n")
        local description
        for _, item in ipairs(require("keymap_tools").list({ mode = "n", kinds = { "mapping" } })) do
          if vim.keycode(item.keys) == wrap_keys then
            description = item.desc
            assert(item.toggle.name == "Wrap" and item.toggle.state == vim.wo.wrap)
          end
        end
        assert(description == (vim.wo.wrap and "Disable " or "Enable ") .. "Wrap", "toggle description is stale")
        mark("visual_picker", "vj" .. actions.input("keymaps.pick", "x"))
        stage = "visual_cancel"
      elseif stage == "visual_cancel" and latest_picker ~= picker and api.nvim_get_mode().mode == "i" then
        visual_picker = latest_picker
        assert(visual_picker.opts.prompt:match("x$"), "Visual picker used wrong mapping mode")
        mark("visual_cancel")
        stage = "visual_restored"
      elseif stage == "visual_restored" and visual_picker.closed and require("keymap_tools.keys").mode() == "x" then
        assert(vim.fn.line("v") == 1 and vim.fn.line(".") == 2, "Visual cancellation lost range")
        mark("visual_escape")
        stage = "universal_normal"
      elseif stage == "universal_normal" and api.nvim_get_mode().mode == "n" then
        mark("universal_normal_open", "\27[47;5u")
        stage = "universal_normal_cancel"
      elseif stage == "universal_normal_cancel" and latest_picker ~= visual_picker and not latest_picker.closed then
        picker = latest_picker
        assert(picker.opts.prompt:match("n$"))
        mark("universal_normal_close", "\27")
        stage = "universal_visual"
      elseif stage == "universal_visual" and picker.closed and api.nvim_get_mode().mode == "n" then
        api.nvim_win_set_cursor(origin, { 1, 0 })
        mark("universal_visual_open", "vj\27[47;5u")
        stage = "universal_visual_cancel"
      elseif stage == "universal_visual_cancel" and latest_picker ~= picker and not latest_picker.closed then
        visual_picker = latest_picker
        assert(visual_picker.opts.prompt:match("x$"))
        mark("universal_visual_close", "\27")
        stage = "universal_visual_restored"
      elseif
        stage == "universal_visual_restored"
        and visual_picker.closed
        and require("keymap_tools.keys").mode() == "x"
      then
        assert(vim.fn.line("v") == 1 and vim.fn.line(".") == 2)
        mark("universal_visual_escape", "\27")
        stage = "universal_insert"
      elseif stage == "universal_insert" and api.nvim_get_mode().mode == "n" then
        api.nvim_buf_set_lines(0, 0, -1, false, { "abcd" })
        api.nvim_win_set_cursor(origin, { 1, 2 })
        vim.keymap.set("i", "<F6>", function()
          assert(api.nvim_get_current_win() == origin and api.nvim_get_mode().mode == "i")
          insert_hits = insert_hits + 1
        end, { buffer = true, desc = "Configured Insert picker action" })
        mark("universal_insert_open", "i\27[47;5u")
        stage = "universal_insert_cancel"
      elseif stage == "universal_insert_cancel" and latest_picker ~= visual_picker and not latest_picker.closed then
        picker = latest_picker
        assert(picker.opts.prompt:match("i$"), "Insert picker used wrong mode")
        mark("universal_insert_close", "\27")
        stage = "universal_insert_restored"
      elseif stage == "universal_insert_restored" and picker.closed and api.nvim_get_mode().mode == "i" then
        assert(api.nvim_get_current_win() == origin and api.nvim_win_get_cursor(origin)[2] == 2)
        mark("legacy_insert_open", "\31")
        stage = "legacy_insert_filter"
      elseif stage == "legacy_insert_filter" and latest_picker ~= picker and not latest_picker.closed then
        picker = latest_picker
        assert(picker.opts.prompt:match("i$"))
        mark("legacy_insert_query", "Configured Insert picker action")
        stage = "legacy_insert_confirm"
      elseif
        stage == "legacy_insert_confirm"
        and picker.query == "Configured Insert picker action"
        and not picker.matching
      then
        assert(#picker.matches == 1)
        mark("legacy_insert_execute", "\r")
        stage = "legacy_insert_executed"
      elseif
        stage == "legacy_insert_executed"
        and picker.closed
        and insert_hits == 1
        and api.nvim_get_mode().mode == "i"
      then
        mark("insert_continue", "z")
        stage = "insert_continued"
      elseif stage == "insert_continued" and api.nvim_get_current_line() == "abzcd" then
        mark("insert_picker_leave", "\27")
        stage = "operator"
      elseif stage == "operator" and api.nvim_get_mode().mode == "n" then
        -- motion-tools.nvim handles selection; keymap-tools owns the waiting hints.
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
        assert(package.loaded["motion_tools.objects"], "motion-tools.nvim failed on first object use")
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
          "PASS configured keymap TUI: dashboard leader hints and burst Space+? with focus restoration, legacy Space+? in Normal/Visual, Ctrl+/ in Normal/Visual/Insert, legacy Ctrl+_ Insert execution and cursor restoration, Wrap, screencast, operator and register hints",
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
