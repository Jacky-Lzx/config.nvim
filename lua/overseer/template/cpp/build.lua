return {
  name = "[C++] Build",
  builder = function()
    local file = vim.fn.expand("%:p")
    local filename_without_ext = vim.fn.expand("%:t:r")
    return {
      cmd = { "clang++" },
      args = {
        file,
        "-o",
        filename_without_ext,
      },
      components = { { "on_output_quickfix", open = true }, "default" },
    }
  end,
  condition = {
    filetype = { "cpp" },
  },
}
