local root = require("utils.platform").dev_plugin_root()

return {
  {
    bootstrap = require("config.bindings").bootstrap("file-tools.nvim", {
      { "<leader>e", "<Cmd>FileTools toggle<CR>", desc = "[Files] Toggle tree" },
      { "<leader>E", "<Cmd>FileTools find<CR>", desc = "[Files] Reveal current file" },
      {
        "<leader>cw",
        function()
          require("file_tools").open({ root = vim.fn.getcwd() })
        end,
        desc = "[Files] Open working directory",
      },
    }, function()
      local unsupported = {
        "<A-h>",
        "<A-l>",
        "[b",
        "]b",
        "<A-w>",
        "<A-u>",
        "<A-S-,>",
        "<A-S-.>",
        "<A-<>",
        "<A->>",
      }
      for index = 1, 9 do
        unsupported[#unsupported + 1] = "<A-" .. index .. ">"
      end
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("ConfigFileToolsKeys", { clear = true }),
        pattern = "file-tools",
        callback = function(event)
          -- Files is a fixed sidebar; buffer actions belong to editing buffers.
          for _, key in ipairs(unsupported) do
            vim.keymap.set("n", key, "<Nop>", {
              buffer = event.buf,
              silent = true,
              nowait = true,
              desc = "Files: buffer action unavailable",
            })
          end
        end,
      })
    end),
    id = "file-tools.nvim",
    dir = root .. "/file-tools.nvim",
    main = "file_tools",
    dependencies = { "theme-tools.nvim" },
    opts = { tree = { width = 40, follow = true } },
    config = function(ctx)
      local opts = ctx.opts
      local files = require("file_tools")
      files.setup(opts)
      for _, action in ipairs({ "Read", "Write" }) do
        vim.api.nvim_create_user_command("Suda" .. action, function(args)
          local ok, err = pcall(files["privileged_" .. action:lower()], args.args ~= "" and args.args or nil, {
            force = args.bang,
          })
          if not ok then
            vim.notify(tostring(err), vim.log.levels.ERROR)
          end
        end, { nargs = "?", bang = true, complete = "file", desc = "Privileged file " .. action:lower() })
      end
    end,
  },
}
