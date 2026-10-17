local directory = require("utils.platform").dev_plugin_root() .. "/image-tools.nvim"
local image_patterns = {}
for _, extension in ipairs({ "png", "jpg", "jpeg", "webp", "avif", "heic", "gif", "bmp", "tif", "tiff", "pdf" }) do
  image_patterns[#image_patterns + 1] = "*."
    .. extension:gsub("%a", function(c)
      return "[" .. c .. c:upper() .. "]"
    end)
end

return {
  {
    -- Local-only until this plugin has a published remote repository.
    dir = directory,
    name = "image-tools.nvim",
    cond = function()
      return vim.uv.fs_stat(directory .. "/lua/image_tools/init.lua") ~= nil
    end,
    lazy = true,
    ft = { "markdown", "tex", "latex", "plaintex", "typst", "html" },
    -- Load and replay the read event before binary file contents are read.
    event = { { event = "BufReadCmd", pattern = image_patterns } },
    cmd = {
      "ImagePreview",
      "ImagePreviewClose",
      "ImagePreviewToggle",
      "ImagePreviewClearCache",
      "ImageCacheClear",
      "ImageInfo",
      "ImageCheckAssets",
      "ImageInsert",
      "ImagePaste",
      "ImagePick",
      "ImageOpen",
      "ImagePage",
      "ImageNextPage",
      "ImagePreviousPage",
      "ImageReload",
      "ImageZoom",
      "ImagePan",
    },
    keys = {
      {
        "<leader>pc",
        function()
          require("image_tools").pick({
            insert = { mode = "reference", insert_strategy = "insert_line_after" },
          })
        end,
        desc = "[Image] Choose images to reference",
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
          require("image_tools").paste({
            process = {
              {
                name = "PNG",
                format = "png",
                command = { "magick", "$INPUT", "-quality", "75", "$OUTPUT" },
              },
              { name = "JPEG", format = "jpg", quality = 75 },
              { name = "WebP", format = "webp", quality = 75 },
              { name = "AVIF", format = "avif", quality = 75 },
              { name = "Original PNG", format = "png" },
            },
            prompt_for_file_name = true,
          })
        end,
        desc = "[Image] Paste with format and filename",
      },
      {
        "<leader>pf",
        function()
          require("image_tools").insert(nil, { mode = "copy" })
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
      -- The old plugin saved in cwd/Figures and emitted document-relative paths.
      root = function(document)
        -- Typst validates resources against the compiler project root.
        return document:match("%.typ$") and vim.fn.getcwd() or vim.fs.dirname(document)
      end,
      insert = {
        directory = "Figures",
        root = function()
          return vim.fn.getcwd()
        end,
        mode = "reference",
        insert_strategy = "insert_after",
        prompt_for_file_name = false,
        file_name = function(ctx)
          return ctx.kind == "clipboard" and os.date("%Y-%m-%d_%H-%M-%S", ctx.timestamp) or ctx.source_name
        end,
        clipboard_backend = vim.fn.has("mac") == 1 and vim.fn.executable("pbctl") == 1 and "pbctl" or "auto",
        template = {
          markdown = function(ctx)
            local path = ctx.file_path:gsub("[%s%%%(%)<>]", function(char)
              return string.format("%%%02X", char:byte())
            end)
            return "![" .. ctx.cursor .. "](" .. path .. ")"
          end,
          -- LaTeX already uses the original figure/caption/label template.
          typst = function(ctx)
            local path = ctx.file_path:gsub("\\", "\\\\"):gsub('"', '\\"')
            return '#figure(\n  image("'
              .. path
              .. '", width: 80%),\n  caption: ['
              .. ctx.cursor
              .. "],\n) <fig-"
              .. ctx.label
              .. ">"
          end,
          html = function(ctx)
            local path = ctx.file_path:gsub("&", "&amp;"):gsub('"', "&quot;"):gsub("<", "&lt;"):gsub(">", "&gt;")
            return '<img src="' .. path .. '" alt="' .. ctx.cursor .. '" />'
          end,
        },
      },
      auto_preview = true,
      position = "bottom_right",
      transport = "auto",
      terminal_cache = { max_images = 32, max_bytes = 64 * 1024 * 1024 },
      max_width = 60,
      max_height = 30,
    },
    config = function(_, opts)
      local image = require("image_tools")
      image.setup(opts)
      -- Preserve :ImageInsert's original clipboard-or-reference behavior.
      vim.api.nvim_create_user_command("ImageInsert", function(args)
        if args.args == "" then
          image.paste()
        else
          image.insert(args.args, { mode = "reference" })
        end
      end, {
        nargs = "?",
        bang = true,
        complete = "file",
        desc = "Insert a clipboard image or reference an existing file",
        force = true,
      })
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
