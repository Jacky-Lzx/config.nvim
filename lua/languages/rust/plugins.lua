return {
  {
    "Saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = {
        crates = {
          enabled = true,
        },
      },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
  },
  {
    "mfussenegger/nvim-dap",
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
        rust = {
          {
            name = "Launch file",
            type = "codelldb",
            request = "launch",
            program = function()
              local cwd = vim.fn.getcwd()
              return coroutine.create(function(dap_co)
                local function finish(path, err)
                  if err then
                    vim.notify(err, vim.log.levels.ERROR)
                  end
                  coroutine.resume(dap_co, path or require("dap").ABORT)
                end
                local ok, err = pcall(vim.system, { "cargo", "build", "--message-format=json" }, {
                  cwd = cwd,
                  text = true,
                }, function(result)
                  vim.schedule(function()
                    if result.code ~= 0 then
                      finish(nil, "cargo build failed:\n" .. (result.stderr or "") .. (result.stdout or ""))
                      return
                    end
                    local executables, seen = {}, {}
                    for line in (result.stdout or ""):gmatch("[^\r\n]+") do
                      local decoded, artifact = pcall(vim.json.decode, line)
                      if not decoded or type(artifact) ~= "table" then
                        finish(nil, "cargo build returned invalid JSON: " .. line)
                        return
                      end
                      local path = artifact.executable
                      if artifact.reason == "compiler-artifact" and type(path) == "string" and not seen[path] then
                        seen[path] = true
                        executables[#executables + 1] = path
                      end
                    end
                    if #executables == 0 then
                      finish(nil, "cargo build emitted no executable artifacts")
                    elseif #executables == 1 then
                      finish(executables[1])
                    else
                      vim.ui.select(executables, { prompt = "Rust executable:" }, function(path)
                        finish(path)
                      end)
                    end
                  end)
                end)
                if not ok then
                  finish(nil, "Could not start cargo build: " .. tostring(err))
                end
              end)
            end,
            args = function()
              local inputstr = vim.fn.input("CommandLine args: ", "")
              local params = {}
              for param in string.gmatch(inputstr, "[^%s]+") do
                table.insert(params, param)
              end
              return params
            end,
          },
        },
      },
    },
  },
}
