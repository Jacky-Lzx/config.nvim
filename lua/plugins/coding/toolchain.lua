return {
  {
    dir = require("utils.platform").dev_plugin_root() .. "/toolchain-tools.nvim",
    name = "toolchain-tools.nvim",
    main = "toolchain",
    lazy = false, -- pin complete parser/query versions before FileType handling
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
    opts = {
      concurrency = 2,
      tools = { path = "append" },
      requirements = function()
        return require("integrations.toolchain").requirements()
      end,
    },
    config = function(_, opts)
      require("toolchain").setup(opts)
      for command, provider in pairs({ MasonToolsInstall = "tool", TSInstallConfigured = "parser" }) do
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
