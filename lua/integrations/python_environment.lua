local M = {}

function M.apply(client)
  if client.name ~= "basedpyright" and client.name ~= "pyright" then
    return
  end
  local python = require("languages.python.interpreter").current({ root = client.root_dir })
  client.settings = client.settings or {}
  client.settings.python = client.settings.python or {}
  if client.settings.python.pythonPath ~= python then
    client.settings.python.pythonPath = python
    if client.initialized then
      client:notify("workspace/didChangeConfiguration", { settings = client.settings })
    end
  end
end

function M.setup(opts)
  local environments = require("python_tools")
  environments.setup(opts)
  require("languages.python.interpreter").set_provider(environments.current, environments.environment)
  local group = vim.api.nvim_create_augroup("ConfigPythonEnvironment", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "PythonEnvironmentChanged",
    callback = function(ev)
      for _, client in ipairs(vim.lsp.get_clients()) do
        local root = client.root_dir and (vim.uv.fs_realpath(client.root_dir) or vim.fs.normalize(client.root_dir))
        if root == ev.data.root then
          M.apply(client)
        end
      end
    end,
  })
  for _, client in ipairs(vim.lsp.get_clients()) do
    M.apply(client)
  end
end

return M
