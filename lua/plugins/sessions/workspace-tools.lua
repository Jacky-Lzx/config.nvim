return {
  {
    dir = require("utils.platform").dev_plugin_root() .. "/workspace-tools.nvim",
    name = "workspace-tools.nvim",
    main = "workspace_tools",
    event = "VeryLazy",
    cmd = {
      "WorkspaceSave",
      "WorkspaceRestore",
      "WorkspaceSearch",
      "WorkspaceLast",
      "WorkspaceDelete",
      "WorkspaceStop",
      "WorkspaceStart",
    },
    -- stylua: ignore
    keys = {
      { "<leader>pw", "<cmd>WorkspaceSave<cr>", desc = "[Workspace] Save" },
      { "<leader>ps", "<cmd>WorkspaceRestore<cr>", desc = "[Workspace] Restore" },
      { "<leader>pS", "<cmd>WorkspaceSearch<cr>", desc = "[Workspace] Search history" },
      { "<leader>pD", "<cmd>WorkspaceDelete<cr>", desc = "[Workspace] Delete" },
    },
    opts = {
      auto_restore = false,
      auto_save = vim.env.NVIM_SMOKE_TEST ~= "1",
      suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
      close_filetypes_on_save = { "checkhealth", "tasktools", "tasktoolsoutput" },
      sessionoptions = "buffers,curdir,folds,tabpages,winsize,winpos,localoptions",
      hooks = {
        pre_save = {
          function(entry)
            require("features.tasks").save_session(entry.id)
          end,
        },
        post_restore = {
          function(entry)
            require("features.tasks").restore_session(entry.id)
          end,
        },
        post_delete = {
          function(entry)
            require("features.tasks").delete_session(entry.id)
          end,
        },
      },
    },
  },
}
