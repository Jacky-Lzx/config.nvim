return {
  name = "[Typst] Build and watch",
  builder = function()
    local file = vim.fn.expand("%:p")
    return {
      cmd = { "typst" },
      args = {
        "watch",
        file,
      },
    }
  end,
  condition = {
    filetype = { "typst" },
  },
}
