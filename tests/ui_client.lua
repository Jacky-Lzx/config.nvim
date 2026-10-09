local M = {}
local unpacker = vim.mpack.Unpacker()
local responses, grids = {}, {}
local sequence = 0

local function redraw(events)
  for _, event in ipairs(events) do
    for i = 2, #event do
      local args = event[i]
      if event[1] == "grid_resize" then
        grids[args[1]] = { width = args[2], height = args[3], rows = {} }
      elseif event[1] == "grid_clear" then
        grids[args[1]].rows = {}
      elseif event[1] == "grid_line" then
        local grid, row, col = grids[args[1]], args[2] + 1, args[3] + 1
        grid.rows[row] = grid.rows[row] or {}
        for _, cell in ipairs(args[4]) do
          for _ = 1, cell[3] or 1 do
            grid.rows[row][col] = cell[1]
            col = col + 1
          end
        end
      elseif event[1] == "grid_scroll" then
        local grid = grids[args[1]]
        local original = vim.deepcopy(grid.rows)
        for row = args[2] + 1, args[3] do
          grid.rows[row] = grid.rows[row] or {}
          for col = args[4] + 1, args[5] do
            local source = original[row + args[6]]
            grid.rows[row][col] = source and source[col + args[7]] or " "
          end
        end
      elseif event[1] == "grid_destroy" then
        grids[args[1]] = nil
      end
    end
  end
end

function M.stdout(_, data)
  -- Channel callbacks represent NUL bytes as newlines within each chunk.
  for i, chunk in ipairs(data) do
    data[i] = chunk:gsub("\n", "\0")
  end
  local bytes, position = table.concat(data, "\n"), 1
  while position <= #bytes do
    local message
    message, position = unpacker(bytes, position)
    if message then
      if message[1] == 1 then
        responses[message[2]] = { error = message[3], result = message[4] }
      elseif message[1] == 2 and message[2] == "redraw" then
        redraw(message[3])
      end
    end
  end
end

function M.request(channel, method, ...)
  sequence = sequence + 1
  local id = sequence
  vim.fn.chansend(channel, vim.mpack.encode({ 0, id, method, { ... } }))
  assert(
    vim.wait(30000, function()
      return responses[id] ~= nil
    end, 10),
    "UI request timed out: " .. method
  )
  local response = responses[id]
  responses[id] = nil
  assert(response.error == vim.NIL, vim.inspect(response.error))
  return response.result
end

function M.notify(channel, method, ...)
  vim.fn.chansend(channel, vim.mpack.encode({ 2, method, { ... } }))
end

function M.screen()
  local grid = assert(grids[1], "No UI grid")
  local rows = {}
  for row = 1, grid.height do
    local cells = {}
    for col = 1, grid.width do
      cells[col] = grid.rows[row] and grid.rows[row][col] or " "
    end
    rows[row] = table.concat(cells)
  end
  return table.concat(rows, "\n")
end

return M
