local M = {}

function M.requirements()
  return { { "gitsigns.nvim", "lua/gitsigns.lua" } }
end

function M.specs()
  return {
    {
      "lewis6991/gitsigns.nvim",
      event = { "BufReadPre", "BufNewFile" },
      cond = function()
        return vim.fn.executable("git") == 1
      end,
      opts = {
        signcolumn = false,
        numhl = true,
        current_line_blame = false,
        attach_to_untracked = true,
        preview_config = { border = "rounded" },
        on_attach = function(bufnr)
          require("features.git.keymaps").attach(bufnr)
        end,
      },
    },
  }
end

function M.check()
  local status = require("config.plugins").status().features.git
  vim.health.start("Git")
  if not status.enabled then
    vim.health.info("Git features are disabled")
  elseif vim.fn.executable("git") == 0 then
    vim.health.warn("Git is unavailable", { "Install Git and restart Neovim" })
  elseif status.available then
    vim.health.ok("Git: " .. vim.fn.exepath("git"))
    vim.health.info("Gitsigns attaches to tracked and untracked files in Git repositories")
  else
    vim.health.warn("Gitsigns is unavailable", { "Run :ConfigPluginsInstall and restart Neovim" })
  end
end

return M
