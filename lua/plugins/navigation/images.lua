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
    cmd = {
      "ImagePreview",
      "ImagePreviewClose",
      "ImagePreviewToggle",
      "ImagePreviewClearCache",
      "ImageInsert",
      "ImagePaste",
      "ImagePick",
    },
    keys = {
      {
        "<leader>pc",
        function()
          require("image_tools").pick()
        end,
        desc = "[Image] Choose images to import",
      },
      {
        "<leader>pI",
        function()
          require("image_tools").paste({ insert_strategy = "insert_line_after" })
        end,
        desc = "[Image] Paste on next line",
      },
      {
        "<leader>pi",
        function()
          require("image_tools").paste({ insert_strategy = "insert_after" })
        end,
        desc = "[Image] Paste after cursor",
      },
      {
        "<leader>PI",
        function()
          require("image_tools").paste({ insert_strategy = "insert_line_before" })
        end,
        desc = "[Image] Paste on previous line",
      },
      {
        "<leader>Pi",
        function()
          require("image_tools").paste({ insert_strategy = "insert_before" })
        end,
        desc = "[Image] Paste before cursor",
      },
      {
        "<leader>pC",
        function()
          local insertion = require("image_tools.insert")
          local context = insertion.capture()
          local formats = vim.tbl_filter(function(format)
            return insertion.supported(context.filetype, "clipboard." .. format)
          end, { "png", "jpg", "webp", "avif" })
          vim.ui.select(formats, { prompt = "Clipboard image format:" }, function(format)
            if format then
              require("image_tools").paste({ context = context, format = format, prompt_for_file_name = true })
            else
              insertion.release(context)
            end
          end)
        end,
        desc = "[Image] Paste with format and filename",
      },
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
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        preview = function(ctx)
          require("integrations.snacks_images").preview(ctx)
        end,
      },
    },
  },
}
