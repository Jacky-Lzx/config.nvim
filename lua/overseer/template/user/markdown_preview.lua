return {
  name = "[Markdown] Preview (gh)",
  priority = 100,
  builder = function()
    local file = vim.fn.expand("%:p")

    return {
      cmd = "gh",
      args = { "markdown-preview", "--port", "3333", file },
      components = {
        { "on_exit_set_status" },
      },
    }
  end,
  condition = {
    filetype = { "markdown" },
  },
}
