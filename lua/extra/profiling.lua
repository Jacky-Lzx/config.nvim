local M = {}

function M.setup()
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
end

return M
