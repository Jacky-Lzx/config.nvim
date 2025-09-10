return {
  name = "[Python] Run current file",
  params = {
    args = {
      type = "list",
      delimiter = " ",
      -- The args are empty if the user just hits enter, without providing any args
      default = {},
    },
  },
  builder = function(params)
    local file = vim.fn.expand("%:p")
    local args = vim.list_extend({ file }, params.args)

    return {
      cmd = { "python" },
      args = args,
    }
  end,
  condition = {
    filetype = { "python" },
  },
}
