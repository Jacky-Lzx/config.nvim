local M = {}

function M.resolve()
  local source = require("utils.paths").config("lazy-lock.json")
  local override = vim.env.NVIM_LAZY_LOCKFILE
  if override and override ~= "" then
    -- Development updates must write to the explicitly selected source checkout.
    return vim.fn.fnamemodify(vim.fn.expand(override), ":p")
  end

  -- Editable checkouts own plugin updates; store-backed deployments cannot.
  if vim.fn.filewritable(source) == 1 then
    return source
  end

  local target = vim.fs.joinpath(vim.fn.stdpath("state"), "lazy", "lazy-lock.json")
  local contents = vim.fn.readfile(source, "b")
  if vim.fn.filereadable(target) == 0 or not vim.deep_equal(contents, vim.fn.readfile(target, "b")) then
    vim.fn.mkdir(vim.fs.dirname(target), "p")
    local temporary = target .. "." .. vim.uv.os_getpid() .. ".tmp"
    assert(vim.fn.writefile(contents, temporary, "b") == 0, "Cannot seed lazy.nvim lockfile")
    local ok, err = vim.uv.fs_rename(temporary, target)
    if not ok then
      vim.uv.fs_unlink(temporary)
      error("Cannot replace lazy.nvim lockfile: " .. tostring(err))
    end
  end
  return target
end

return M
