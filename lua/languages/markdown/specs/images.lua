return {
  {
    "Jacky-Lzx/image-insert.nvim",
    dev = true,
    keys = {
      {
        "<leader>pI",
        function()
          require("image-insert").insert_image({ insert_strategy = "insert_line_after" })
        end,
        desc = "[image-insert] Insert next line",
      },
      {
        "<leader>pi",
        function()
          require("image-insert").insert_image({ insert_strategy = "insert_after" })
        end,
        desc = "[image-insert] Insert after cursor",
      },
      {
        "<leader>PI",
        function()
          require("image-insert").insert_image({ insert_strategy = "insert_line_before" })
        end,
        desc = "[image-insert] Insert prev line",
      },
      {
        "<leader>Pi",
        function()
          require("image-insert").insert_image({ insert_strategy = "insert_before" })
        end,
        desc = "[image-insert] Insert before cursor",
      },
      {
        "<leader>pC",
        function()
          require("image-insert").insert_image({
            process = {
              { cmd = "magick - -quality 75 png:-", extension = "png" },
              { cmd = "magick - -quality 75 jpg:-", extension = "jpg" },
              { cmd = "magick - -quality 75 webp:-", extension = "webp" },
              { cmd = "magick - avif:-", extension = "avif" },
              { cmd = "", extension = "png" },
              { cmd = "", extension = "jpg" },
              { cmd = "", extension = "avif" },
            },
            prompt_for_file_name = true,
          })
        end,
        desc = "[image-insert] Paste image from system clipboard",
      },
      {
        "<leader>pc",
        function()
          Snacks.picker.files({
            ft = { "jpg", "jpeg", "png", "webp", "heic", "avif", "pdf" },
            -- Override what happens when you press <CR> (confirm)
            actions = {
              confirm = function(picker, _)
                -- Get multi-selection (or current item if nothing is selected)
                local items = picker:selected({ fallback = true })
                -- Convert items -> file paths
                local files = vim.tbl_map(function(it)
                  -- for the files picker items typically have it.file (and it.text)
                  return it.file or it.text
                end, items)

                picker:close()

                -- Schedule if you’re going to open/edit files, etc.
                vim.schedule(function()
                  Snacks.notify("Selected:\n" .. table.concat(files, "\n"), { title = "image-insert.nvim" })

                  for _, file in ipairs(files) do
                    require("image-insert").insert_image({ insert_strategy = "insert_line_after" }, file)
                  end
                end)
              end,
            },
          })
        end,
        desc = "[image-insert] Choose an image to paste",
      },
    },
    opts = {
      dir_path = "Figures",
      prompt_for_file_name = false,
      relative_to_current_file = false,
      insert_relative_to = "file",
      process = { cmd = "magick - avif:-", extension = "avif" },
    },
  },
}
