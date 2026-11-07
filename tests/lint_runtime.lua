local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.runtimepath:prepend(root)
local spec = require("plugins.coding.lint-tools")[1]
vim.opt.runtimepath:prepend(require("utils.platform").dev_plugin_root() .. "/" .. spec.id)
local lint = require("lint_tools")
spec.config({ opts = spec.opts })
assert(vim.fn.exists(":LintToolsInfo") == 2)
assert(not package.loaded.lint)
local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(buf, vim.env.NVIM_TEST_TMP .. "/lint-runtime.py")
vim.bo[buf].filetype = "python"
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "print(undefined_name) # teh" })
local current = vim.api.nvim_get_current_buf()
local clients, typos = vim.lsp.get_clients, false
vim.lsp.get_clients = function(opts)
  assert(opts.bufnr == buf and opts.name == "typos_lsp")
  return typos and { {} } or {}
end
local function save()
  vim.api.nvim_buf_call(buf, function()
    vim.cmd("silent write")
  end)
  assert(vim.wait(10000, function()
    local states = lint.status(buf)
    if #states ~= 2 then
      return false
    end
    for _, state in ipairs(states) do
      if state.status == "running" or state.status == "queued" then
        return false
      end
      assert(state.status == "done" or state.status == "skipped", vim.inspect(state))
    end
    return true
  end, 10))
  assert(vim.api.nvim_get_current_buf() == current)
end
save()
local function diagnostics(name)
  return vim.diagnostic.get(buf, { namespace = require("lint_tools.diagnostics").namespace(name) })
end
assert(#diagnostics("ruff") > 0, "configured Ruff must report errors")
if vim.fn.executable("codespell") == 1 then
  assert(#diagnostics("codespell") > 0)
end
typos = true
save()
assert(#diagnostics("codespell") == 0, "typos_lsp must suppress and clear codespell")
assert(lint.status(buf)[1].reason == "condition returned false")
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'print("clean")' })
save()
assert(#diagnostics("ruff") == 0)
vim.lsp.get_clients = clients
lint.disable()
print("Configured lint runtime: save triggers, Ruff, codespell policy and clean-result lifecycle passed")
