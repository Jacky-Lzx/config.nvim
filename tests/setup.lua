-- Compatibility entry point used by file-tools.nvim's configured PTY driver.
return dofile(assert(vim.env.NVIM_CONFIG_ROOT) .. "/tests/support/setup.lua")
