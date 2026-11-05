local directory = require("utils.platform").dev_plugin_root() .. "/image-tools.nvim"

return {
  {
    bootstrap = require("config.bindings").bootstrap("image-tools.nvim", {
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
    }, nil),
    id = "image-tools.nvim",
    -- Local-only until this plugin has a published remote repository.
    dir = directory,
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
    config = function(ctx)
      require("image_tools.bootstrap").setup(ctx.opts)
      require("integrations.image_tools").setup()
      -- Preserve the clipboard-or-reference behavior of the personal shortcut.
      local function alias()
        vim.api.nvim_create_user_command("ImageInsert", function(args)
          local image = require("image_tools.bootstrap").ensure()
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
      end
      vim.api.nvim_create_autocmd("User", { pattern = "ImageToolsReady", callback = alias })
      alias()
    end,
  },
}
