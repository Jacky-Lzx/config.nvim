return {
  {
    "Jacky-Lzx/image-insert.nvim",
    dev = true,
    keys = {
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
