return {
  {
    id = "dap-tools.nvim",
    opts = {
      presets = {
        python = {
          adapter_python = function()
            return assert(
              require("utils.platform").debugpy_python(),
              "debugpy is not installed; run :ConfigToolsInstall"
            )
          end,
          python = function(ctx)
            return require("languages.python.interpreter").current(ctx and { buf = ctx.buf, root = ctx.root } or nil)
          end,
          env = function(ctx)
            return require("languages.python.interpreter").environment(
              ctx and { buf = ctx.buf, root = ctx.root } or nil
            )
          end,
        },
      },
    },
  },
}
