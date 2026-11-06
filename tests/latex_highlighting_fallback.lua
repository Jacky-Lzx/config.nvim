vim.opt.rtp:prepend(assert(vim.env.NVIM_CONFIG_ROOT))
local policy = require("languages.latex.highlighting")
local start, stop, highlight = vim.treesitter.start, vim.treesitter.stop, vim.api.nvim_set_hl
local stopped = 0
vim.treesitter.stop = function()
  stopped = stopped + 1
end
vim.api.nvim_set_hl = function()
  error("Buffer attachment must not reset theme groups")
end
vim.treesitter.start = function(buf)
  vim.bo[buf].syntax = ""
  error("fixture: parser unavailable")
end
for _, case in ipairs({ { "tex", "tex" }, { "", "tex" }, { "customtex", "customtex" } }) do
  vim.bo.syntax = case[1]
  local ok, err = policy.attach(0)
  assert(not ok and tostring(err):find("parser unavailable", 1, true))
  assert(vim.bo.syntax == case[2], "Lost syntax fallback: " .. case[2])
end
assert(stopped == 3)
vim.bo.filetype, vim.bo.syntax = "plaintex", ""
assert(not policy.attach(0) and vim.bo.syntax == "plaintex")
vim.treesitter.start = function() end
assert(policy.attach(0) and vim.bo.syntax == "")
vim.b.config_treesitter_disabled = true
vim.treesitter.start = function()
  error("Protected buffers must not start Tree-sitter")
end
assert(not policy.attach(0))
vim.b.config_treesitter_disabled = nil
vim.treesitter.start, vim.treesitter.stop, vim.api.nvim_set_hl = start, stop, highlight
print("LaTeX highlighting: parser failure retains syntax, partial starts stop, and theme groups stay plugin-owned")
