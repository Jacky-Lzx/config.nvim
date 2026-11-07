vim.opt.rtp:prepend(assert(vim.env.NVIM_CONFIG_ROOT))
local before = vim.o.rtp
local old_prof, old_dev, old_root = vim.env.PROF, vim.env.NVIM_DEV_PLUGIN_ROOT, vim.env.NVIM_PLUGIN_ROOT
vim.env.PROF = "0"
require("extra.profiling").setup()
assert(vim.o.rtp == before and not package.loaded["debug_tools.profiler"])
local temp = assert(vim.env.NVIM_TEST_TMP) .. "/profiler"
vim.env.NVIM_DEV_PLUGIN_ROOT, vim.env.NVIM_PLUGIN_ROOT = temp .. "/dev", temp .. "/packages"
local development = temp .. "/dev/debug-tools.nvim"
vim.fn.mkdir(development .. "/lua/debug_tools", "p")
vim.fn.writefile({ "return {}" }, development .. "/lua/debug_tools/profiler.lua")
local calls = 0
package.loaded["debug_tools.profiler"] = {
  startup = function(opts)
    assert(opts.event == "ConfigReady" and opts.save)
    calls = calls + 1
  end,
}
vim.env.PROF = "1"
require("extra.profiling").setup()
assert(vim.list_contains(vim.opt.rtp:get(), development))
vim.env.NVIM_DEV_PLUGIN_ROOT = temp .. "/missing"
require("extra.profiling").setup()
assert(vim.list_contains(vim.opt.rtp:get(), temp .. "/packages/debug-tools.nvim") and calls == 2)
vim.env.PROF, vim.env.NVIM_DEV_PLUGIN_ROOT, vim.env.NVIM_PLUGIN_ROOT = old_prof, old_dev, old_root
print("Profiling: disabled startup is inert; explicit profiling supports development and managed checkouts")
