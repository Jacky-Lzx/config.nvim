local M = {}

function M.requirements()
  return { { "mini.surround", "lua/mini/surround.lua" } }
end

function M.specs()
  return {
    {
      "nvim-mini/mini.surround",
      version = "*",
      lazy = vim.g.config_plugin_install and true or false,
      config = function()
        vim.keymap.set({ "n", "x", "o" }, "s", "<Nop>", { desc = "Surround prefix" })
        require("mini.surround").setup()
      end,
    },
  }
end

return M
