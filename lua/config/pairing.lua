local M = {}
local source

function M.source()
  if not source then
    local dir = vim.fs.joinpath(require("config.platform").dev_plugin_root(), "pairs.nvim")
    source = {
      dir = dir,
      available = vim.fn.filereadable(vim.fs.joinpath(dir, "lua", "pairs", "init.lua")) == 1,
    }
  end
  return source
end

-- blink.cmp owns Enter. An absent local checkout uses its normal newline fallback.
function M.newline()
  if M.source().available then
    return require("pairs").expr("<CR>")
  end
end

function M.check()
  local source = M.source()
  vim.health.start("Pairing plugin")
  if not source.available then
    vim.health.warn(
      "pairs.nvim is unavailable at " .. source.dir .. "; pairing is disabled and Enter uses normal newline"
    )
    vim.health.info("Set NVIM_DEV_PLUGIN_ROOT to the parent of the local pairs.nvim checkout")
    return
  end
  vim.health.ok("pairs.nvim source: local checkout (" .. source.dir .. ")")
  local result = vim.system({ "git", "-C", source.dir, "rev-parse", "HEAD" }, { text = true }):wait()
  if result.code == 0 then
    vim.health.info("Local revision: " .. vim.trim(result.stdout))
  end
end

return M
