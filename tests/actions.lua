-- Compatibility entry point used by file-tools.nvim's configured PTY assertions.
return dofile(assert(vim.env.NVIM_CONFIG_ROOT) .. "/tests/support/actions.lua")
