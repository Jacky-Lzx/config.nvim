local root = require("utils.platform").dev_plugin_root()
local directory = root .. "/pdf-view.nvim"

return {
  {
    -- Local-only until this reader has a published remote repository.
    dir = directory,
    name = "pdf-view.nvim",
    cond = function()
      return vim.uv.fs_stat(directory .. "/lua/pdf_view/init.lua") ~= nil
    end,
    lazy = false, -- Register PDF interception before startup files are read.
    opts = { fit = "width", transport = "auto" },
    config = function(_, opts)
      require("pdf_view").setup(opts)
    end,
  },
}
