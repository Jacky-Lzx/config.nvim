local root = require("utils.platform").dev_plugin_root()
local directory = root .. "/pdf-view.nvim"
local images = root .. "/image-tools.nvim"

return {
  {
    -- Local-only until this reader has a published remote repository.
    dir = directory,
    name = "pdf-view.nvim",
    cond = function()
      return vim.uv.fs_stat(directory .. "/lua/pdf_view/init.lua") ~= nil
        and vim.uv.fs_stat(images .. "/lua/image_tools/init.lua") ~= nil
    end,
    lazy = false, -- Register PDF interception before startup files are read.
    dependencies = { { dir = images, name = "image-tools.nvim" } },
    opts = { fit = "width", transport = "auto" },
    config = function(_, opts)
      require("pdf_view").setup(opts)
    end,
  },
}
