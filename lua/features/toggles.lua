local M = {}

-- Report live state only after an explicit action, never while inspecting keymaps.
function M.notify(name, enabled)
  if type(enabled) == "boolean" then
    vim.notify(name .. ": " .. (enabled and "Enabled" or "Disabled"), vim.log.levels.INFO, { title = "Toggle" })
  end
end

function M.map(owner, lhs, opts)
  opts = vim.deepcopy(opts or {})
  local mode = opts.mode or "n"
  opts.mode = nil
  opts.desc = opts.desc or ("Toggle " .. owner.name)
  local buf = opts.buffer
  if buf == 0 or buf == true then
    buf = vim.api.nvim_get_current_buf()
  elseif buf == false then
    buf = nil
  end
  local callback, registration = require("keymap_tools").register_toggle("config.toggle." .. owner.id, {
    buf = buf,
    modes = type(mode) == "table" and mode or { mode },
    keys = lhs,
    name = owner.name,
    get = function(ctx)
      if ctx.win then
        return vim.api.nvim_win_call(ctx.win, owner.get)
      end
    end,
    set = owner.set,
  })
  require("config.bindings").set("config.toggle." .. owner.id .. ":" .. (buf or 0), {
    vim.tbl_extend("force", opts, { lhs, callback, id = "toggle." .. owner.id, mode = mode, buffer = buf }),
  })
  return registration
end

-- Scroll entry keys are personal policy; the UI module owns only the behavior.
function M.scroll_bindings()
  local bindings = require("config.bindings")
  bindings.set("config.scroll", {})
  local scroll = package.loaded["ui_tools.scroll"]
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
  local function option(name, lhs, label, on, off)
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
    }, lhs)
  end
  option("spell", "<leader>ts", "Spelling")
  option("wrap", "<leader>tw", "Wrap")
  option("relativenumber", "<leader>tL", "Relative Number")
  option("conceallevel", "<leader>tc", "Conceal", vim.o.conceallevel > 0 and vim.o.conceallevel or 2, 0)
  option("background", "<leader>tb", "Dark Background", "dark", "light")
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
  }, "<leader>tl")
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
  }, "<leader>tT")
  M.map({
    id = "inlay_hints",
    name = "Inlay Hints",
    get = function()
      return vim.lsp.inlay_hint.is_enabled()
    end,
    set = function(state)
      vim.lsp.inlay_hint.enable(state)
    end,
  }, "<leader>th")
  for _, spec in ipairs({ { "animate", "<leader>ta", "Animation" }, { "scroll", "<leader>tS", "Scroll animation" } }) do
    M.map({
      id = spec[1],
      name = spec[3],
      get = function()
        local module = package.loaded["ui_tools." .. spec[1]]
        return module ~= nil and module.enabled == true
      end,
      set = function()
        require("ui_tools").toggle(spec[1])
        if spec[1] == "scroll" then
          M.scroll_bindings()
        end
      end,
    }, spec[2])
  end
  for _, spec in ipairs({
    { "running", "<leader>tPp", "Profiler", "toggle" },
    { "highlighted", "<leader>tPh", "Profiler Highlights", "highlights" },
  }) do
    M.map({
      id = spec[1],
      name = spec[3],
      get = function()
        local p = package.loaded["debug_tools.profiler"]
        return p ~= nil and p[spec[1]] == true
      end,
      set = function()
        require("debug_tools").profiler[spec[4]]()
      end,
    }, spec[2])
  end
  require("keymap_tools").register(
    "debug-tools.profiler",
    { groups = { { prefix = "<leader>tP", label = "[profiler]" } } }
  )
end
return M
