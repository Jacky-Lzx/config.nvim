local M = {}

function M.setup()
  local create = vim.api.nvim_create_user_command
  for alias, command in pairs({ W = "write", Wq = "wq", Q = "quit" }) do
    create(alias, command, { desc = "Alias for :" .. command, force = true })
  end

  create("ConfigInfo", function()
    vim.print(require("config").info())
  end, { desc = "Show active selection, plugin phases and integration state", force = true })

  if require("languages").is_enabled("python") then
    -- The alias remains available before a Python buffer has initialized its provider.
    create("VenvSelect", function(args)
      require("config.plugins").manager:activate("python-tools.nvim")
      vim.api.nvim_cmd({ cmd = "PythonEnv", args = args.args ~= "" and { args.args } or {}, bang = args.bang }, {})
    end, { nargs = "?", bang = true, complete = "file", desc = "Select project Python environment" })
  end

  create("ConvertTabToSpace", "%s/\t/  /g", {})

  create("KeyTest", function()
    print("Press any key...")
    local key = vim.fn.getcharstr()
    print("Key: " .. vim.fn.keytrans(key))
  end, {
    desc = "Show the next pressed key",
  })

  create("Titlecase", function(opts)
    require("editing_tools").titlecase(opts.line1, opts.line2)
  end, { range = true, desc = "Apply English title case to the line range" })
end

return M
