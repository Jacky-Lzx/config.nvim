return {
  root_dir = function(buf, on_dir)
    on_dir(require("workspace_tools.environments.python").root({ buf = buf }))
  end,
  on_init = function(client)
    require("integrations.python_environment").apply(client)
  end,
}
