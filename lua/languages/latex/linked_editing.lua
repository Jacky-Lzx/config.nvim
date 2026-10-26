local M = {}
local sessions = {}
local method = "textDocument/linkedEditingRange"

-- Neovim 0.12 ignores the server's wordPattern and rejects '*' and Unicode.
-- Keep this LaTeX adapter on public APIs until native linked editing honors it.
-- The Lua character class below matches texquill's returned name pattern.
local function valid_name(lines)
  return #lines == 1 and not lines[1]:find("[%s{}\\%%]")
end

function M.attach(client, bufnr)
  if not client:supports_method(method, bufnr) then
    return
  end
  if vim.lsp.linked_editing_range then
    vim.lsp.linked_editing_range.enable(false, { client_id = client.id })
  end
  if sessions[bufnr] then
    if sessions[bufnr].client == client then
      return
    end
    sessions[bufnr].detach()
  end

  local ns = vim.api.nvim_create_namespace("latex.linked_editing:" .. client.id .. ":" .. bufnr)
  local group = vim.api.nvim_create_augroup("LatexLinkedEditing" .. bufnr, { clear = true })
  local state = { client = client, ids = {}, generation = 0 }
  sessions[bufnr] = state

  local function clear()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end
    state.ids = {}
  end

  local function range(id)
    local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, id, { details = true })
    if #mark == 0 then
      return
    end
    return { mark[1], mark[2], mark[3].end_row, mark[3].end_col }
  end

  local function refresh()
    state.generation = state.generation + 1
    local generation = state.generation
    if state.pending then
      client:cancel_request(state.pending)
      state.pending = nil
    end
    if vim.api.nvim_get_current_buf() ~= bufnr then
      clear()
      return
    end
    local tick = vim.api.nvim_buf_get_changedtick(bufnr)
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    local ok, request_id = client:request(method, params, function(err, result)
      if sessions[bufnr] ~= state or generation ~= state.generation then
        return
      end
      state.pending = nil
      if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_buf_get_changedtick(bufnr) ~= tick then
        return
      end
      clear()
      if err or not result or vim.api.nvim_get_current_buf() ~= bufnr then
        return
      end
      for i, item in ipairs(result.ranges) do
        local first = item.start
        local last = item["end"]
        local first_line = vim.api.nvim_buf_get_lines(bufnr, first.line, first.line + 1, false)[1] or ""
        local last_line = vim.api.nvim_buf_get_lines(bufnr, last.line, last.line + 1, false)[1] or ""
        local start_col = vim.str_byteindex(first_line, client.offset_encoding, first.character, false)
        local end_col = vim.str_byteindex(last_line, client.offset_encoding, last.character, false)
        state.ids[i] = vim.api.nvim_buf_set_extmark(bufnr, ns, first.line, start_col, {
          end_row = last.line,
          end_col = end_col,
          right_gravity = false,
          end_right_gravity = true,
          hl_group = "LspReferenceTarget",
        })
      end
    end, bufnr)
    if ok then
      state.pending = request_id
    end
  end

  local function update()
    if #state.ids < 2 or vim.api.nvim_get_current_buf() ~= bufnr then
      return
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]
    local active
    for i, id in ipairs(state.ids) do
      local current = range(id)
      if
        current
        and (row > current[1] or row == current[1] and col >= current[2])
        and (row < current[3] or row == current[3] and col <= current[4])
      then
        active = i
        break
      end
    end
    if not active then
      return
    end
    local edited = range(state.ids[active])
    if not edited then
      clear()
      return
    end
    local replacement = vim.api.nvim_buf_get_text(bufnr, edited[1], edited[2], edited[3], edited[4], {})
    if not valid_name(replacement) then
      clear()
      return
    end
    for i, id in ipairs(state.ids) do
      if i ~= active then
        local target = range(id)
        if target then
          local text = vim.api.nvim_buf_get_text(bufnr, target[1], target[2], target[3], target[4], {})
          if not vim.deep_equal(text, replacement) then
            -- An undo must restore its own complete edit without being mirrored.
            if not pcall(vim.cmd.undojoin) then
              return
            end
            vim.api.nvim_buf_set_text(bufnr, target[1], target[2], target[3], target[4], replacement)
          end
        end
      end
    end
  end

  state.detach = function()
    state.generation = state.generation + 1
    if state.pending then
      client:cancel_request(state.pending)
    end
    clear()
    vim.api.nvim_del_augroup_by_id(group)
    sessions[bufnr] = nil
  end
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
    group = group,
    buffer = bufnr,
    callback = function()
      update()
      refresh()
    end,
  })
  vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter" }, { group = group, buffer = bufnr, callback = refresh })
  vim.api.nvim_create_autocmd("LspDetach", {
    group = group,
    buffer = bufnr,
    callback = function(event)
      if event.data.client_id == client.id then
        state.detach()
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", { group = group, buffer = bufnr, callback = state.detach })
  refresh()
end

return M
