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
vim.keymap.set("n", "<D-v>", '"+p', { silent = true })
vim.keymap.set("x", "<D-v>", '"+P', { silent = true })
vim.keymap.set("i", "<D-v>", "<C-R><C-O>+", { silent = true })
vim.keymap.set("c", "<D-v>", "<C-R>+", { silent = true })
vim.keymap.set("t", "<D-v>", function()
  vim.api.nvim_paste(vim.fn.getreg("+"), false, -1)
end, { silent = true })
