local M = {}

--- Helper to get visually selected text
local function get_visual_selection()
  local s_start = vim.fn.getpos("'<")
  local s_end = vim.fn.getpos("'>")
  local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)

  if #lines == 0 then
    return nil
  end

  if #lines == 1 then
    lines[1] = string.sub(lines[1], s_start[3], s_end[3])
  else
    lines[1] = string.sub(lines[1], s_start[3])
    lines[#lines] = string.sub(lines[#lines], 1, s_end[3])
  end

  return table.concat(lines, "\n")
end

--- Opens the link or path under the cursor or selection
function M.open_at_cursor()
  local mode = vim.api.nvim_get_mode().mode
  local path

  if mode:match("[vV]") or mode == "␖" then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
    vim.schedule(function()
      path = get_visual_selection()
      M.process_open(path)
    end)
  else
    path = vim.fn.expand("<cfile>")
    M.process_open(path)
  end
end

--- Internal helper to check if a file exists
local function file_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat ~= nil
end

--- Internal helper to process and open the path
function M.process_open(path)
  if path == "" or path == nil then
    vim.notify("No path or URL found", vim.log.levels.WARN)
    return
  end

  -- Trim whitespace
  path = path:gsub("^%s*(.-)%s*$", "%1")

  -- 1. Check if it's already a URL or Absolute Path
  if path:match("^%a+://") or path:match("^/") then
    -- Path is already valid for 'open'
  else
    -- 2. Trial 1: Relative to current file
    local path_rel_file = vim.fn.expand("%:p:h") .. "/" .. path

    -- 3. Trial 2: Relative to CWD (Where Neovim opened)
    local cwd = vim.fn.getcwd()
    local path_rel_cwd = cwd .. "/" .. path

    if file_exists(path_rel_file) then
      path = path_rel_file
    elseif file_exists(path_rel_cwd) then
      path = path_rel_cwd
    else
      -- 4. Trial 3: Relative to Project Root (.git, etc.)
      local root = vim.fs.root(0, { ".git" })
      local path_rel_root = root and (root .. "/" .. path) or nil

      if path_rel_root and file_exists(path_rel_root) then
        path = path_rel_root
      else
        -- Fallback: If none exist, we default to CWD trial so 'open' can
        -- at least try to handle it (or show its own error).
        path = path_rel_cwd
      end
    end
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
