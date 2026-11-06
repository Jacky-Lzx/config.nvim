return {
  {
    main = "format_tools",
    id = "format-tools.nvim",
    enabled = true,
    -- Local checkout until this new plugin has a published source.
    dir = vim.fs.joinpath(require("utils.platform").dev_plugin_root(), "format-tools.nvim"),
    after = { "toolchain-tools.nvim" },
    dependencies = { "toolchain-tools.nvim" },
    opts = {
      formatters_by_ft = vim.tbl_extend(
        "force",
        { ["_"] = { "trim_whitespace" } },
        require("languages").current().formatters
      ),
      formatters = require("languages").current().formatter_options,
      format_on_save = function(bufnr)
        -- Disable with a global or buffer-local variable
        if
          vim.g.enable_autoformat
          and not vim.b[bufnr].disable_autoformat
          and vim.b[bufnr].enable_autoformat ~= false
        then
          return { timeout_ms = 500, lsp_format = "fallback" }
        end
      end,
    },
    config = function(ctx)
      do
        if vim.g.enable_autoformat == nil then
          vim.g.enable_autoformat = true
        end
        -- Honor a session preference before the first save.
        require("features.toggles").map({
          id = "autoformat",
          name = "Auto format",
          get = function()
            return vim.g.enable_autoformat
          end,
          set = function(state)
            vim.g.enable_autoformat = state
          end,
        }, "<leader>tf", { desc = "Toggle auto format" })
      end
      require("config.bindings").set("format-tools.nvim", {
        {
          "<leader>gf",
          function()
            require("format_tools").format({ lsp_format = "fallback" })
          end,
          desc = "Format",
        },
      })
      local opts = ctx.opts
      require("format_tools").setup(opts)
    end,
  },
}
