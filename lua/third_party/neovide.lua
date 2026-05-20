vim.o.guifont = "SauceCodePro NF:b,LXGW WenKai Mono Medium"

vim.g.neovide_opacity = 0.7
vim.g.neovide_normal_opacity = 0.7

vim.g.neovide_input_macos_option_key_is_meta = "only_left"

-- -- Add keybinds to change transparency
local change_transparency = function(delta)
  vim.g.neovide_opacity = math.max(math.min(vim.g.neovide_opacity + delta, 1), 0)
  vim.g.neovide_normal_opacity = math.max(math.min(vim.g.neovide_normal_opacity + delta, 1), 0)
end
-- stylua: ignore
vim.keymap.set({ "n", "v", "o" }, "<D-]>", function() change_transparency(0.1) end)
-- stylua: ignore
vim.keymap.set({ "n", "v", "o" }, "<D-[>", function() change_transparency(-0.1) end)

vim.g.neovide_scale_factor = 1.0
local change_scale_factor = function(delta)
  vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
end
vim.keymap.set("n", "<D-=>", function()
  change_scale_factor(1.1)
end)
vim.keymap.set("n", "<D-->", function()
  change_scale_factor(1 / 1.1)
end)
--
-- -- Allow clipboard copy paste in neovim
vim.g.neovide_input_use_logo = 1
vim.api.nvim_set_keymap("", "<D-v>", "+p<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("!", "<D-v>", "<C-R>+", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "<D-v>", "<C-R>+", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<D-v>", "<C-R>+", { noremap = true, silent = true })
