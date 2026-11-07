local M = {}

-- Report live state only after an explicit action, never while inspecting keymaps.
function M.notify(name, enabled)
  if type(enabled) == "boolean" then
    vim.notify(name .. ": " .. (enabled and "Enabled" or "Disabled"), vim.log.levels.INFO, { title = "Toggle" })
  end
end

-- Pure entry construction also works before plugin runtime paths are mounted.
function M.binding(id, action, opts)
  local definition = require("config.toggle_keys").get(id)
  return vim.tbl_extend("force", { definition.lhs, action, desc = "Toggle " .. definition.name }, opts or {})
end

function M.metadata(id, get)
  local definition = require("config.toggle_keys").get(id)
  return { keys = definition.lhs, name = definition.name, get = get }
end

function M.map(owner, lhs, opts)
  opts = vim.deepcopy(opts or {})
  local definition = (not lhs or not owner.name) and require("config.toggle_keys").get(owner.id)
  lhs = lhs or definition.lhs
  local name = owner.name or definition.name
  local mode = opts.mode or "n"
  opts.mode = nil
  opts.desc = opts.desc or ("Toggle " .. name)
  local buf = opts.buffer
  if buf == 0 or buf == true then
    buf = vim.api.nvim_get_current_buf()
  elseif buf == false then
    buf = nil
  end
  local function get(ctx)
    if owner.scope == nil or owner.scope == "window" then
      if ctx.win then
        return vim.api.nvim_win_call(ctx.win, function()
          return owner.get(ctx)
        end)
      end
    else
      return owner.get(ctx)
    end
  end
  local keymaps = require("keymap_tools")
  local source = "config.toggle." .. owner.id .. ":" .. (buf or 0)
  local modes = type(mode) == "table" and mode or { mode }
  local callback, registration = keymaps.register_toggle(source, {
    buf = buf,
    modes = modes,
    keys = lhs,
    name = name,
    get = get,
    set = owner.set,
    action = owner.action,
    notify = owner.notify,
  })
  require("config.bindings").set(source, {
    vim.tbl_extend("force", opts, { lhs, callback, mode = mode, buffer = buf }),
  })
  return registration
end

-- Scroll entry keys are personal policy; the UI module owns only the behavior.
function M.scroll_bindings()
  local bindings = require("config.bindings")
  bindings.set("config.scroll", {})
  local ui = package.loaded.ui_tools
  local scroll = ui and ui.get_state("scroll")
  if not scroll or not scroll.enabled then
    return
  end
  local existing, entries = {}, {}
  for _, mapping in ipairs(vim.api.nvim_get_keymap("n")) do
    existing[vim.keycode(mapping.lhs)] = true
  end
  for _, key in ipairs({ "<C-d>", "<C-u>", "<C-f>", "<C-b>", "<C-e>", "<C-y>" }) do
    if not existing[vim.keycode(key)] then
      entries[#entries + 1] = {
        key,
        function()
          require("ui_tools.scroll").scroll(key, vim.v.count)
        end,
        desc = "Smooth native scroll",
      }
    end
  end
  bindings.set("config.scroll", entries)
end

function M.setup()
  local function option(name, label, on, off)
    if on == nil then
      on = true
    end
    if off == nil then
      off = false
    end
    M.map({
      id = name,
      name = label,
      get = function()
        return vim.o[name] == on
      end,
      set = function(state)
        vim.opt_local[name] = state and on or off
      end,
    })
  end
  option("spell", "Spelling")
  option("wrap", "Wrap")
  option("relativenumber", "Relative Number")
  option("conceallevel", "Conceal", vim.o.conceallevel > 0 and vim.o.conceallevel or 2, 0)
  option("background", "Dark Background", "dark", "light")
  local saved = {}
  M.map({
    id = "line_number",
    name = "Line Numbers",
    get = function()
      return vim.wo.number or vim.wo.relativenumber
    end,
    set = function(state)
      local win = vim.api.nvim_get_current_win()
      if state then
        local value = saved[win] or { true, true }
        vim.wo.number, vim.wo.relativenumber = value[1], value[2]
      else
        saved[win] = { vim.wo.number, vim.wo.relativenumber }
        vim.wo.number, vim.wo.relativenumber = false, false
      end
    end,
  })
  M.map({
    id = "treesitter",
    name = "Treesitter Highlight",
    get = function()
      return vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil
    end,
    set = function(state)
      vim.b.config_treesitter_disabled = not state
      vim.treesitter[state and "start" or "stop"]()
    end,
  })
  M.map({
    id = "inlay_hints",
    name = "Inlay Hints",
    get = function()
      return vim.lsp.inlay_hint.is_enabled()
    end,
    set = function(state)
      vim.lsp.inlay_hint.enable(state)
    end,
  })
  for _, spec in ipairs({ { "animate", "Animation" }, { "scroll", "Scroll animation" } }) do
    M.map({
      id = spec[1],
      name = spec[2],
      get = function()
        local ui = package.loaded.ui_tools
        local state = ui and ui.get_state(spec[1])
        return state ~= nil and state.enabled == true
      end,
      set = function()
        require("ui_tools").toggle(spec[1])
        if spec[1] == "scroll" then
          M.scroll_bindings()
        end
      end,
    })
  end
  for _, spec in ipairs({
    { "running", "Profiler", "toggle" },
    { "highlighted", "Profiler Highlights", "highlights" },
  }) do
    M.map({
      id = spec[1],
      name = spec[2],
      get = function()
        local debug = package.loaded.debug_tools
        local state = debug and debug.get_state().profiler
        return state ~= nil and state[spec[1]] == true
      end,
      set = function()
        require("debug_tools").profiler[spec[3]]()
      end,
    })
  end
  require("keymap_tools").register("config.toggle.groups", { groups = require("config.toggle_keys").groups() })
end
return M
