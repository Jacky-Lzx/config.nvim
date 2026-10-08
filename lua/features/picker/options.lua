local M = {}

function M.get()
  return {
    enabled = true,
    actions = {
      copy_selected = {
        desc = "Copy selected to clipboard",
        action = function(picker)
          local items = picker:selected({ fallback = true })
          local lines = vim.tbl_map(function(item)
            return item.file or item.text
          end, items)
          vim.fn.setreg("+", table.concat(lines, "\n"))
          vim.notify(("Copied %d item(s) to clipboard"):format(#lines), vim.log.levels.INFO)
        end,
      },
      system_open = {
        desc = "Open with system app",
        action = function(picker)
          for _, item in ipairs(picker:selected({ fallback = true })) do
            local path = item.file or item.text
            if path then
              local _, err = vim.ui.open(path)
              if err then
                vim.notify(err, vim.log.levels.ERROR)
              end
            else
              vim.notify("No file or text to open", vim.log.levels.ERROR)
            end
          end
        end,
      },
    },
    win = {
      input = {
        keys = {
          ["<Tab>"] = { "select_and_prev", mode = { "i", "n" } },
          ["<S-Tab>"] = { "select_and_next", mode = { "i", "n" } },
          ["<A-Up>"] = { "history_back", mode = { "n", "i" } },
          ["<A-Down>"] = { "history_forward", mode = { "n", "i" } },
          ["<A-j>"] = { "list_down", mode = { "n", "i" } },
          ["<A-k>"] = { "list_up", mode = { "n", "i" } },
          ["<C-u>"] = { "preview_scroll_up", mode = { "n", "i" } },
          ["<C-d>"] = { "preview_scroll_down", mode = { "n", "i" } },
          ["<A-u>"] = { "list_scroll_up", mode = { "n", "i" } },
          ["<A-d>"] = { "list_scroll_down", mode = { "n", "i" } },
          ["<C-j>"] = {},
          ["<C-k>"] = {},
          ["<C-y>"] = { "copy_selected", mode = { "n", "i" } },
          ["<C-o>"] = { "system_open", mode = { "n", "i" } },
        },
      },
    },
    sources = {
      select = { layout = { reverse = false, preset = "select" } },
    },
    layout = { preset = "default" },
    layouts = {
      default = {
        reverse = true,
        layout = {
          backdrop = false,
          width = 0.8,
          min_width = 60,
          height = 0.9,
          box = "vertical",
          border = true,
          title = "{title} {live} {flags}",
          title_pos = "center",
          { win = "preview", title = "{preview}", height = 0.6, border = "bottom" },
          { win = "list", border = "none" },
          { win = "input", height = 1, border = "top" },
        },
      },
    },
  }
end

return M
