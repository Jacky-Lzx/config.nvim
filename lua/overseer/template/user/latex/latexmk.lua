return {
  name = "[LaTeX] Build using latexmk",
  builder = function()
    local file = vim.fn.expand("%:p")
    return {
      cmd = { "latexmk" },
      args = {
        file,
      },
    }
  end,
  condition = {
    filetype = { "tex" },
  },
}
