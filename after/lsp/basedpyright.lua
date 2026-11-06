return {
  root_dir = function(buf, on_dir)
    -- Native LSP startup may resolve roots before the manager's FileType callback.
    require("config.plugins").manager:activate("workspace-tools.python")
    on_dir(require("workspace_tools.environments.python").root({ buf = buf }))
  end,
  on_init = function(client)
    require("integrations.python_environment").apply(client)
  end,
}
