return {
  name = "Verilog runner",
  builder = function()
    -- local file = vim.fn.expand("%:p")
    -- local filename_without_ext = vim.fn.expand("%:t:r")
    return {
      cmd = { "sh" },
      args = {
        "compile.sh",
      },
    }
  end,
  condition = {
    filetype = { "verilog" },
  },
}
