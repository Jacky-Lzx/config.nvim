return {
  name = "Convert markdown to pdf",
  builder = function()
    local file = vim.fn.expand("%:p")
    local filename_without_ext = vim.fn.expand("%:t:r")
    return {
      cmd = { "pandoc" },
      args = {
        file,
        "-o",
        filename_without_ext .. ".pdf",
        "--pdf-engine=xelatex",
        "-V",
        'CJKmainfont="华文黑体"',
      },
    }
  end,
  condition = {
    filetype = { "markdown" },
  },
}
