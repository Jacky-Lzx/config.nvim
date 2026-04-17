local M = {}

--- Helper to get visually selected text
local function get_visual_selection()
  local s_start = vim.fn.getpos("'<")
  local s_end = vim.fn.getpos("'>")
  local n_lines = math.abs(s_end[2] - s_start[2]) + 1
  local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)

  if #lines == 0 then
    return nil
  end

  -- Handle single line selection
  if #lines == 1 then
    lines[1] = string.sub(lines[1], s_start[3], s_end[3])
  else
    -- Handle multi-line (unlikely for paths, but for completeness)
    lines[1] = string.sub(lines[1], s_start[3])
    lines[#lines] = string.sub(lines[#lines], 1, s_end[3])
  end

  return table.concat(lines, "\n")
end

--- Opens the link or path under the cursor or selection using the system 'open' command.
function M.open_at_cursor()
  local mode = vim.api.nvim_get_mode().mode
  local path

  if mode == "v" or mode == "V" or mode == "" then
    -- Must exit visual mode first to update the marks '< and '>
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)

    -- Schedule the execution to ensure marks are updated
    vim.schedule(function()
      path = get_visual_selection()
      M.process_open(path)
    end)
    return
  else
    path = vim.fn.expand("<cfile>")
    M.process_open(path)
  end
end

--- Internal helper to process and open the path
function M.process_open(path)
  if path == "" or path == nil then
    vim.notify("No path or URL found", vim.log.levels.WARN)
    return
  end

  -- Trim whitespace
  path = path:gsub("^%s*(.-)%s*$", "%1")

  -- Detect if it's a URL or a file path
  if not path:match("^%a+://") and not path:match("^/") then
    path = vim.fn.expand("%:p:h") .. "/" .. path
  end

  vim.notify("Opening: " .. path, vim.log.levels.INFO)

  vim.fn.jobstart({ "open", path }, {
    detach = true,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        vim.notify("Failed to open: " .. path, vim.log.levels.ERROR)
      end
    end,
  })
end

return M
