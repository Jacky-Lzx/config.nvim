return {
  name = "GH Markdown Preview",
  condition = {
    filetype = { "markdown" },
  },
  builder = function()
    local file = vim.fn.expand("%:p")

    return {
      cmd = { "gh" },
      args = { "markdown-preview", file },
      name = "Preview: " .. vim.fn.expand("%:t"),

      components = {
        -- { "on_output_summarize", max_lines = 10 },
        "on_exit_set_status",
        "on_complete_notify",
        "unique",
      },
    }
  end,
}
