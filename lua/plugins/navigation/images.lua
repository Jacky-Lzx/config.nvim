local directory = require("utils.platform").dev_plugin_root() .. "/image-tools.nvim"

return {
  {
    -- Local-only until this plugin has a published remote repository.
    dir = directory,
    name = "image-tools.nvim",
    cond = function()
      return vim.uv.fs_stat(directory .. "/lua/image_tools/init.lua") ~= nil
    end,
    event = "VeryLazy",
    cmd = { "ImagePreview", "ImagePreviewClose", "ImagePreviewToggle", "ImagePreviewClearCache", "ImageInsert" },
    keys = {
      {
        "<leader>pf",
        function()
          require("image_tools").insert()
        end,
        desc = "[Image] Import image file",
      },
      {
        "<leader>si",
        function()
          require("image_tools").hover()
        end,
        desc = "[Image] Preview image on current line",
      },
      {
        "<leader>ui",
        function()
          require("image_tools").toggle()
        end,
        desc = "[Image] Toggle automatic preview",
      },
    },
    opts = {
      insert = { directory = "Figures", mode = "copy" },
      auto_preview = true,
      position = "bottom_right",
      transport = "auto",
      terminal_cache = { max_images = 32, max_bytes = 64 * 1024 * 1024 },
      max_width = 60,
      max_height = 30,
    },
    config = function(_, opts)
      require("image_tools").setup(opts)
    end,
  },
}
