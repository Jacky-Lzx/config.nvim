-- Do not show `~` when the buffer is end
-- See `https://github.com/catppuccin/nvim/commit/50c34a2cf18776a77f770fcf5df777de6fe69e08`
vim.opt.fillchars:append({ eob = " " })
-- Do not show strikethroughs in the diff view
vim.opt.fillchars:append({ diff = " " })

-- Snacks profiler settings
-- Use `PROF=1` nvim to start profiling
if vim.env.PROF then
  -- example for lazy.nvim
  -- change this to the correct path for your plugin manager
  local snacks = vim.fn.stdpath("data") .. "/lazy/snacks.nvim"
  vim.opt.rtp:append(snacks)
  ---@diagnostic disable-next-line: missing-fields
  require("snacks.profiler").startup({
    startup = {
      event = "VimEnter", -- stop profiler on this event. Defaults to `VimEnter`
      -- event = "UIEnter",
      -- event = "VeryLazy",
    },
  })
end
