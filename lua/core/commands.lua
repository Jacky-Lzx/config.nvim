local M = {}

function M.setup()
  for alias, command in pairs({ W = "write", Wq = "wq", Q = "quit" }) do
    vim.api.nvim_create_user_command(alias, command, { desc = "Alias for :" .. command, force = true })
  end

  vim.api.nvim_create_user_command("ConfigInfo", function()
    vim.print(require("config").info())
  end, { desc = "Show Neovim version and configuration paths", force = true })
end

return M
