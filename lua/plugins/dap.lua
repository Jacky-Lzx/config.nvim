return {
  {
    "igorlfs/nvim-dap-view",
    dependencies = {
      {
        -- Solve the display issue with lualine
        "nvim-lualine/lualine.nvim",
        optional = true,
        opts = { options = { disabled_filetypes = { winbar = { "dap-view", "dap-view-term", "dap-repl" } } } },
      },
    },
    -- stylua: ignore
    keys = {
      { "<leader>Du", function() require("dap-view").toggle() end, desc = "[DAP view] Toggle dap-view" },
    },
    ---@module 'dap-view'
    ---@type dapview.Config
    opts = {
      winbar = {
        sections = { "scopes", "repl", "watches", "breakpoints", "exceptions" },
        default_section = "scopes",
        controls = { enabled = true },
      },
      windows = {
        height = 0.25,
        position = "below",
        terminal = {
          width = 0.1,
          position = "right",
          -- List of debug adapters for which the terminal should be ALWAYS hidden
          hide = {},
        },
      },
      help = { border = "rounded" },
      auto_toggle = true,
    },
  },

  {
    -- Show variable values as virtual texts
    "theHamsta/nvim-dap-virtual-text",
    -- Disabled by default
    enabled = false,
    opts = { virt_text_pos = "eol" },
  },

  {
    "mfussenegger/nvim-dap",
    dependencies = { "igorlfs/nvim-dap-view" },
    -- stylua: ignore
    keys = {
      { "<F5>",       function() require("dap").continue() end,                                                        mode = "n",          desc = "[DAP] Continue" },
      { "<F6>",       function() require("dap").step_over() end,                                                       mode = "n",          desc = "[DAP] Step over" },
      { "<F7>",       function() require("dap").step_into() end,                                                       mode = "n",          desc = "[DAP] Step into" },
      { "<F8>",       function() require("dap").step_out() end,                                                        mode = "n",          desc = "[DAP] Step out" },
      { "<F9>",       function() require("dap").pause() end,                                                           mode = "n",          desc = "[DAP] Pause" },
      { "<F10>",      function() require("dap").terminate() end,                                                       mode = "n",          desc = "[DAP] Terminate" },
      { "<Leader>b",  function() require("dap").toggle_breakpoint() end,                                               mode = "n",          desc = "[DAP] Toggle breakpoint" },
      { "<Leader>B",  function() require("dap").set_breakpoint() end,                                                  mode = "n",          desc = "[DAP] Set breakpoint" },
      -- Remove the <leader>D binding in "x" mode
      { "<Leader>D" , mode = "x" },
      { "<Leader>Dr", function() require("dap").repl.open() end,                                                       mode = "n",          desc = "[DAP] Repl open" },
      { "<Leader>Dl", function() require("dap").run_last() end,                                                        mode = "n",          desc = "[DAP] Run last" },
      { "<Leader>Dd", function() require("dap.ui.widgets").hover() end,                                                mode = { "n", "v" }, desc = "[DAP] Widgets hover" },
      { "<Leader>Dp", function() require("dap.ui.widgets").preview() end,                                              mode = { "n", "v" }, desc = "[DAP] Widgets preview" },
      { "<Leader>Df", function() local widgets = require("dap.ui.widgets") widgets.centered_float(widgets.frames) end, mode = {"n"},        desc = "[DAP] Float frames" },
      { "<Leader>Ds", function() local widgets = require("dap.ui.widgets") widgets.centered_float(widgets.scopes) end, mode = {"n"},        desc = "[DAP] Float scopes" },
    },

    config = function()
      local dap = require("dap")
      dap.defaults.fallback.external_terminal = { command = "kitty" }

      --stylua: ignore
      local dap_breakpoint = {
        -- Nerd font: nf-cod-activate_breakpoints
        breakpoint = { text = "", texthl = "DapBreakpoint", linehl = "DapBreakpoint", numhl = "DapBreakpoint" },
        condition  = { text = "", texthl = "DapBreakpoint", linehl = "DapBreakpoint", numhl = "DapBreakpoint" },
        rejected   = { text = "", texthl = "DapBreakpoint", linehl = "DapBreakpoint", numhl = "DapBreakpoint" },
        logpoint   = { text = "", texthl = "DapLogPoint",   linehl = "DapLogPoint",   numhl = "DapLogPoint"   },
        stopped    = { text = "", texthl = "DapStopped",    linehl = "DapStopped",    numhl = "DapStopped"    },
      }
      vim.fn.sign_define("DapBreakpoint", dap_breakpoint.breakpoint)
      vim.fn.sign_define("DapBreakpointCondition", dap_breakpoint.condition)
      vim.fn.sign_define("DapBreakpointRejected", dap_breakpoint.rejected)
      vim.fn.sign_define("DapLogPoint", dap_breakpoint.logpoint)
      vim.fn.sign_define("DapStopped", dap_breakpoint.stopped)
    end,
  },
}
