return {
  name = "[C++] Run",
  params = {
    executable = {
      type = "string",
      -- Default is the filename without extension
      default = "./" .. vim.fn.expand("%:t:r"),
      optional = false,
      order = 1,
    },
    args = {
      type = "list",
      delimiter = " ",
      -- The args are empty if the user just hits enter, without providing any args
      default = {},
      order = 2,
    },
  },
  builder = function(params)
    -- Check if the executable exists
    if vim.fn.filereadable(params.executable) == 0 then
      require("overseer.log"):error("Executable not found: " .. params.executable)
      return { cmd = "exit", args = { "1" } }
    end
    return {
      cmd = { params.executable },
      args = params.args,
    }
  end,
  condition = {
    filetype = { "cpp" },
  },
}
