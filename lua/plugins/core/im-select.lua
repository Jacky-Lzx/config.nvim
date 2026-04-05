return {
  -- Change input method automatically
  -- {
  --   "keaising/im-select.nvim",
  --   lazy = false,
  --   cond = function()
  --     return vim.uv.os_uname().sysname == "Darwin"
  --   end,
  --   opts = {
  --     -- Restore the default input method state when the following events are triggered
  --     set_default_events = { "VimEnter", "InsertLeave", "CmdlineLeave" },
  --   },
  --   config = function(_, opts)
  --     require("im_select").setup(opts)
  --   end,
  -- },
}
