local M = {}

function M.check()
  local source = require("features.pairing").source()
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
