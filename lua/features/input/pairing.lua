local M = {}

function M.source()
  local root = vim.env.NVIM_DEV_PLUGIN_ROOT
  if not root or root == "" then
    root = "~/Documents/Github/nvim_plugins"
  end
  local dir = vim.fs.joinpath(vim.fn.expand(root), "pairs.nvim")
  return { dir = dir, available = vim.fn.filereadable(vim.fs.joinpath(dir, "lua/pairs/init.lua")) == 1 }
end

function M.setup()
  require("pairs").setup({ treesitter = true, mappings = { cr = false } })
  vim.keymap.set("i", "<Plug>(config-input-newline)", function()
    return require("pairs").expr("<CR>") or vim.keycode("<CR>")
  end, { expr = true, replace_keycodes = false, silent = true })
end

function M.newline()
  if package.loaded.pairs and require("pairs").status().initialized then
    -- Flush preceding text before evaluating the empty-pair newline decision.
    return vim.keycode("<Ignore><Plug>(config-input-newline)")
  end
end

return M
