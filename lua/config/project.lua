local M = {}
local active_file

local function canonical(path)
  return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
end

function M.find(path)
  if not path or path == "" or path == "-" or path:match("^%a[%w+.-]*://") then
    return
  end
  path = vim.fn.fnamemodify(path, ":p")
  local stat = vim.uv.fs_stat(path)
  local directory = stat and stat.type == "directory" and path or vim.fs.dirname(path)
  local file = vim.fs.find(".nvim-plugins.lua", { path = directory, upward = true, type = "file" })[1]
  return file and canonical(file)
end

function M.startup_file()
  -- The first local argument owns the session; remote URIs/stdin use cwd.
  for _, argument in ipairs(vim.fn.argv()) do
    if argument ~= "-" and not argument:match("^%a[%w+.-]*://") then
      local file = M.find(argument)
      if file then
        return file
      end
      break
    end
  end
  return M.find(vim.uv.cwd())
end

function M.info()
  return { file = active_file, root = active_file and vim.fs.dirname(active_file), selection = "startup" }
end

function M.setup(file)
  active_file = file
  local seen, checked = {}, {}
  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("ConfigProject", { clear = true }),
    callback = function(event)
      local path = vim.api.nvim_buf_get_name(event.buf)
      if vim.bo[event.buf].buftype ~= "" or path == "" or checked[event.buf] == path then
        return
      end
      checked[event.buf] = path
      local target = M.find(path)
      if target == active_file or (not target and not active_file) then
        return
      end
      local key = target or "none"
      if seen[key] then
        return
      end
      seen[key] = true
      local origin = active_file or "no project configuration"
      vim.schedule(function()
        vim.notify(
          "This session keeps "
            .. origin
            .. ". Restart Neovim in the target project to apply "
            .. (target or "its default configuration")
            .. ".",
          vim.log.levels.WARN,
          { title = "Project configuration" }
        )
      end)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = "ConfigProject",
    callback = function(event)
      checked[event.buf] = nil
    end,
  })
end

return M
