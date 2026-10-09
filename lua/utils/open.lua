local M = {}

--- Opens the link or path under the cursor or selection
function M.open_at_cursor()
  local mode = vim.api.nvim_get_mode().mode
  local path

  if mode == "v" or mode == "V" or mode == "\22" then
    path = table.concat(
      vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), {
        type = mode,
        exclusive = vim.o.selection == "exclusive",
      }),
      "\n"
    )
    vim.cmd.normal({ args = { "\27" }, bang = true })
  else
    path = vim.fn.expand("<cfile>")
  end
  M.process_open(path)
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

  local ok, err = require("config.platform").open(path)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
end

return M
