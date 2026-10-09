local platform = require("utils.platform")

local lldb_adapter = {
  name = "lldb-dap",
  type = "executable",
  command = platform.is("macos") and "xcrun" or "lldb-dap",
  options = { source_filetype = "swift" },
}

if platform.is("macos") then
  lldb_adapter.args = { "lldb-dap" }
end

return {
  {
    "mfussenegger/nvim-dap",
    ft = "swift",
    optional = true,
    opts = {
      adapters = {
        lldb = lldb_adapter,
      },
      configurations = {
        swift = {
          {
            name = "[Swift] Launch executable",
            type = "lldb",
            request = "launch",
            program = function()
              return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/.build/debug/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
            args = function()
              local args_str = vim.fn.input("Commandline args: ")
              return vim.split(args_str, " ", { trimempty = true })
            end,
          },
        },
      },
    },
  },
}
