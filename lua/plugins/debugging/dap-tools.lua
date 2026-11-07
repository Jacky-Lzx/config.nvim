return {
  {
    id = "dap-tools.nvim",
    source = "Jacky-Lzx/dap-tools.nvim",
    version = "main",
    dev = true,
    main = "dap_tools",
    dependencies = { "nvim-dap" },
    children = {
      {
        id = "nvim-dap",
        source = "mfussenegger/nvim-dap",
        mount = "on-demand",
        start = false,
      },
    },
    opts = { ui = { height = 0.28, auto_open = true, auto_close = false } },
    config = function(ctx)
      local opts = ctx.opts
      opts.backend_loader = function()
        ctx.mount("nvim-dap")
      end
      local tools = require("dap_tools")
      tools.setup(opts)
      require("config.bindings").set("dap-tools.nvim", {
        { "<F5>", tools.continue, desc = "[DAP] Launch / continue" },
        { "<F6>", "<cmd>DapToolsStepOver<cr>", desc = "[DAP] Step over" },
        { "<F7>", "<cmd>DapToolsStepInto<cr>", desc = "[DAP] Step into" },
        { "<F8>", "<cmd>DapToolsStepOut<cr>", desc = "[DAP] Step out" },
        { "<F9>", "<cmd>DapToolsPause<cr>", desc = "[DAP] Pause" },
        { "<F10>", "<cmd>DapToolsTerminate<cr>", desc = "[DAP] Terminate" },
        { "<leader>b", "<cmd>DapToolsBreakpoint<cr>", desc = "[DAP] Toggle breakpoint" },
        { "<leader>B", "<cmd>DapToolsBreakpoint condition<cr>", desc = "[DAP] Conditional breakpoint" },
        { "<leader>Dc", "<cmd>DapToolsRun<cr>", desc = "[DAP] Choose configuration" },
        { "<leader>Da", "<cmd>DapToolsRun!<cr>", desc = "[DAP] Launch with arguments" },
        { "<leader>Dr", tools.repl, desc = "[DAP] REPL" },
        { "<leader>Dl", tools.run_last, desc = "[DAP] Run last" },
        { "<leader>Dd", tools.hover, mode = { "n", "x" }, desc = "[DAP] Inspect expression" },
        {
          "<leader>Dp",
          function()
            tools.open("scopes", true)
          end,
          desc = "[DAP] Variables",
        },
        {
          "<leader>Df",
          function()
            tools.open("stack", true)
          end,
          desc = "[DAP] Call stack",
        },
        { "<leader>Ds", tools.sessions, desc = "[DAP] Switch session" },
        { "<leader>Dw", "<cmd>DapToolsWatch<cr>", desc = "[DAP] Add watch" },
        { "<leader>Db", "<cmd>DapToolsBreakpoint log<cr>", desc = "[DAP] Logpoint" },
        {
          require("config.toggle_keys").get("dap.view").lhs,
          tools.toggle,
          desc = "[DAP] Toggle panel",
        },
      })
    end,
  },
}
