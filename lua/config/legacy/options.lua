-- Set block cursor with blinking in all modes
-- vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50"
--   .. ",a:blinkwait700-blinkoff500-blinkon500-Cursor/lCursor"
--   .. ",sm:block-blinkwait175-blinkoff150-blinkon175"

-- Enables project-local `.nvim.lua` configuration file
vim.o.exrc = vim.env.NVIM_SMOKE_TEST ~= "1"
