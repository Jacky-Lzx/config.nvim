local M = {}

function M.setup()
  for alias, command in pairs({ W = "write", Wq = "wq", Q = "quit" }) do
    vim.api.nvim_create_user_command(alias, command, { desc = "Alias for :" .. command, force = true })
  end

  vim.api.nvim_create_user_command("ConfigInfo", function()
    vim.print(require("config").info())
  end, { desc = "Show Neovim version and configuration paths", force = true })

  vim.api.nvim_create_user_command("ConfigPluginsInstall", function()
    require("config.plugins").install()
  end, { desc = "Install plugins for enabled features", force = true })
end

return M
