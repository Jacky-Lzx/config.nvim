return {
  {
    id = "toolchain-tools.nvim",
    source = "git@github.com:Jacky-Lzx/toolchain-tools.nvim.git",
    dev = true,
    main = "toolchain",
    opts = {
      concurrency = 2,
      tools = {
        path = "append",
        lockfile = require("utils.paths").root .. "/toolchain-lock.json",
        sources = require("config.tool_sources"),
      },
      requirements = function()
        return require("integrations.toolchain").requirements()
      end,
    },
    config = function(ctx)
      local opts = ctx.opts
      require("toolchain").setup(opts)
      -- Keep :Mason from abbreviating to :MasonToolsInstall after removing Mason.
      vim.api.nvim_create_user_command("Mason", function()
        require("toolchain").open()
      end, { desc = "Open the unified tool manager", force = true })
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
