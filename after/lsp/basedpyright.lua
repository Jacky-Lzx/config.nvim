return {
  root_dir = function(buf, on_dir)
    -- Native LSP startup may resolve roots before the manager's FileType callback.
    require("config.plugins").manager:activate("python-tools.nvim")
    on_dir(require("python_tools").root({ buf = buf }))
  end,
  on_init = function(client)
    require("integrations.python_environment").apply(client)
  end,
}
