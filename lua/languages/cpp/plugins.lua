return {
  {
    "mfussenegger/nvim-dap",
    ft = { "c", "cpp" },
    optional = true,
    opts = {
      -- See `https://codeberg.org/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation`
      adapters = {
        codelldb = {
          name = "codelldb",
          type = "executable",
          command = "codelldb", -- or if not in $PATH: "/absolute/path/to/codelldb"

          -- On windows you may have to uncomment this:
          -- detached = false,
        },
      },
      configurations = {
        cpp = {
          {
            name = "[C/C++] Launch file",
            type = "codelldb",
            request = "launch",
            program = function()
              return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
            args = function()
              local args_str = vim.fn.input("Commandline args: ")
              return vim.split(args_str, " ", { plain = true })
            end,
          },
        },
      },
      configuration_aliases = { c = "cpp" },
    },
  },
}
