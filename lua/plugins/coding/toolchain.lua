return {
  {
    dir = require("utils.platform").dev_plugin_root() .. "/toolchain-tools.nvim",
    name = "toolchain-tools.nvim",
    main = "toolchain",
    cmd = {
      "Toolchain",
      "ToolchainPlan",
      "ToolchainInstall",
      "ToolchainRetry",
      "ToolchainCancel",
      "ToolchainLog",
      "MasonToolsInstall",
      "TSInstallConfigured",
    },
    dependencies = { "mason-org/mason.nvim", "nvim-treesitter/nvim-treesitter" },
    opts = {
      concurrency = 2,
      requirements = function()
        return require("integrations.toolchain").requirements()
      end,
    },
    config = function(_, opts)
      require("toolchain").setup(opts)
      for command, provider in pairs({ MasonToolsInstall = "mason", TSInstallConfigured = "treesitter" }) do
        vim.api.nvim_create_user_command(command, function()
          require("integrations.toolchain").install(provider)
        end, {
          desc = "Install configured " .. provider .. " dependencies through toolchain-tools",
          force = true,
        })
      end
    end,
  },
}
