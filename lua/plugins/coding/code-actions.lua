local directory = require("utils.platform").dev_plugin_root() .. "/code-actions.nvim"

return {
  {
    name = "code-actions.nvim",
    dir = directory,
    -- This local project has no published remote yet. Native gra remains available
    -- on machines where the development checkout is absent.
    enabled = vim.uv.fs_stat(directory) ~= nil,
    dependencies = { "folke/snacks.nvim" },
    event = "LspAttach",
    keys = {
      {
        "<leader>a",
        function()
          require("code_actions").code_action()
        end,
        desc = "[LSP] Code action",
        mode = { "n", "x" },
      },
      {
        "<A-a>",
        function()
          require("code_actions").code_action()
        end,
        desc = "[LSP] Code action",
        mode = "i",
      },
    },
    opts = {
      backend = "delta", -- Set "vim" to use the native diff preview.
      delta = { args = {} },
    },
    config = function(_, opts)
      require("code_actions").setup(opts)
    end,
  },
}
