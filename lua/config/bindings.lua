-- Ordinary mappings only. No loading proxies or manager activation callbacks.
local M = { entries = {} }
local states, owners = {}, {}
local aliases = { v = { "x", "s" }, [""] = { "n", "x", "s", "o" }, ["!"] = { "i", "c" } }

local function mapping(mode, lhs, buffer)
  if not buffer then
    local current = vim.fn.maparg(lhs, mode, false, true)
    if current.buffer == 0 then
      return current
    end
  end
  local maps = buffer and vim.api.nvim_buf_get_keymap(buffer, mode) or vim.api.nvim_get_keymap(mode)
  local raw = vim.keycode(lhs)
  for _, item in ipairs(maps) do
    if item.lhsraw == raw or vim.keycode(item.lhs) == raw then
      item.buf = nil -- API map lists include this alias; maparg() only returns buffer.
      return item
    end
  end
end

local function clear(id)
  local state = states[id]
  if not state then
    return
  end
  if state.group then
    pcall(vim.api.nvim_del_augroup_by_id, state.group)
  end
  for key, record in pairs(state.maps) do
    if owners[key] == record then
      if not record.buffer or vim.api.nvim_buf_is_valid(record.buffer) then
        local current = mapping(record.mode, record.lhs, record.buffer)
        if current and vim.deep_equal(current, record.installed) then
          vim.keymap.del(record.mode, record.lhs, { buffer = record.buffer })
        end
      end
      owners[key] = nil
    end
  end
end

function M.set(id, entries)
  entries = type(entries) == "function" and entries() or entries
  clear(id)
  local state = { maps = {} }
  states[id] = state
  M.entries[id] = entries
  for _, entry in ipairs(entries) do
    assert(type(entry[1]) == "string", id .. ": a mapping needs a string left-hand side")
    if entry[2] ~= nil then
      local options = {}
      for key, value in pairs(entry) do
        if type(key) == "string" and key ~= "mode" and key ~= "ft" and key ~= "id" then
          options[key] = value
        end
      end
      options.silent = options.silent ~= false
      local function bind(buffer)
        local target = buffer or options.buffer
        if target == true or target == 0 then
          target = vim.api.nvim_get_current_buf()
        end
        if target == false then
          target = nil
        end
        local lhs = entry[1]
        local modes = type(entry.mode) == "table" and entry.mode or { entry.mode or "n" }
        for _, mode in ipairs(modes) do
          for _, atomic in ipairs(aliases[mode] or { mode }) do
            vim.keymap.set(atomic, lhs, entry[2], vim.tbl_extend("force", options, { buffer = target }))
            local installed = assert(mapping(atomic, lhs, target))
            local key = atomic .. ":" .. (target or 0) .. ":" .. installed.lhsraw
            -- Store the installed spelling so later leader changes cannot redirect cleanup.
            local record = { mode = atomic, lhs = installed.lhs, buffer = target, installed = installed }
            state.maps[key], owners[key] = record, record
          end
        end
      end
      if entry.ft then
        state.group = state.group or vim.api.nvim_create_augroup("ConfigBindings_" .. id, { clear = true })
        local filetypes = type(entry.ft) == "table" and entry.ft or { entry.ft }
        vim.api.nvim_create_autocmd("FileType", {
          group = state.group,
          pattern = filetypes,
          callback = function(event)
            bind(event.buf)
          end,
        })
        for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
          if vim.list_contains(filetypes, vim.bo[buffer].filetype) then
            bind(buffer)
          end
        end
      else
        bind(nil)
      end
    end
  end
end

-- One owner per buffer, with the same conditional cleanup as global mappings.
function M.set_buffer(id, buffer, entries)
  local owner = id .. "." .. buffer
  local scoped = vim.deepcopy(entries)
  for _, entry in ipairs(scoped) do
    entry.buffer = buffer
  end
  M.set(owner, scoped)
  if #scoped > 0 then
    local state = states[owner]
    state.group = state.group or vim.api.nvim_create_augroup("ConfigBindings_" .. owner, { clear = true })
    vim.api.nvim_create_autocmd("BufWipeout", {
      group = state.group,
      buffer = buffer,
      once = true,
      callback = function()
        clear(owner)
        states[owner], M.entries[owner] = nil, nil
      end,
    })
  end
  return owner
end
return M
