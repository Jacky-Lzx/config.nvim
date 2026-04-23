return {
  name = "[LaTeX] Build using tectonic",
  builder = function()
    local file = vim.fn.expand("%:p")
    return {
      cmd = { "tectonic" },
      args = {
        "-X",
        "compile",
        file,
        "--synctex",
        "--keep-logs",
        "--keep-intermediates",
      },
    }
  end,
  condition = {
    filetype = { "tex" },
  },
}
