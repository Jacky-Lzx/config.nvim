return {
  {
    config = function(ctx)
      require("config.bindings").set("img-clip.nvim", {
        {
          "<leader>pi",
          function()
            require("img-clip").paste_image({ insert_at_current_line = true, insert_at_current_line_after = true })
          end,
          desc = "[Img-Clip] Paste image from system clipboard",
        },
        {
          "<leader>pI",
          function()
            require("img-clip").paste_image({ insert_at_current_line = true, insert_at_current_line_after = false })
          end,
          desc = "[Img-Clip] Paste image from system clipboard",
        },
        {
          "<leader>pc",
          function()
            require("selection_tools").files({
              multi = false,
              globs = { "*.{jpg,jpeg,png,webp,heic,avif}" },
              on_choice = function(item)
                if item then
                  require("img-clip").paste_image({}, item.file)
                end
              end,
            })
          end,
          desc = "[Img-Clip] Choose an image to paste",
        },
      })
      require("img-clip").setup(ctx.opts)
    end,
    main = "img-clip",
    id = "img-clip.nvim",
    source = "HakonHarnes/img-clip.nvim",
    enabled = false,
    dev = true,
    opts = {
      default = {
        dir_path = "Figures", ---@type string | fun(): string

        extension = "avif", ---@type string
        -- Convert clipboard image to avif format before saving
        process_cmd = "magick - avif:-", ---@type string
        copy_images = true,
        formats = { "jpeg", "jpg", "png", "heic", "pdf", "avif" }, ---@type string[]

        use_absolute_path = false, ---@type boolean
        relative_to_current_file = false, ---@type boolean

        insert_mode_after_paste = true,

        insert_template_after_cursor = true,
        insert_at_current_line = true,
        insert_at_current_line_after = false,

        show_dir_path_in_prompt = true, ---@type boolean

        prompt_for_file_name = false, ---@type boolean
        file_name = "%y-%m-%d_%H-%M-%S", ---@type string

        -- This setting also affect copying texts using Cmd+v. If it is enabled, when copying texts, a warning about
        -- "the content is not image" will be shown.
        drag_and_drop = { enabled = false },
      },
      filetypes = {
        markdown = {
          -- Encode spaces and special characters in file path
          url_encode_path = true, ---@type boolean

          template = "![$CURSOR]($FILE_PATH)", ---@type string | fun(context: table): string
        },
      },
    },
  },
}
