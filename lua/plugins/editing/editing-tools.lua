return {
  {
    config = function(ctx)
      do
        if vim.fn.maparg("gX", "n") == "" then
          vim.keymap.set("n", "gX", function()
            vim.ui.open(vim.fn.expand("<cfile>"))
          end, { desc = "Open URI under cursor" })
        end
      end
      require("config.bindings").set("editing-tools.nvim", function()
        local keys = {}
        -- Keep Vim's URI opener reachable after gx becomes exchange.
        local uri = vim.fn.maparg("gx", "n", false, true)
        if vim.fn.maparg("gX", "n") == "" and (uri.desc or ""):find("URI under cursor", 1, true) then
          keys[#keys + 1] = { "gX", uri.callback or uri.rhs, desc = uri.desc }
        end
        local function plug(lhs, action, mode)
          keys[#keys + 1] = {
            lhs,
            "<Plug>(EditingTools-" .. action .. ")",
            mode = mode,
            desc = "[Editing] " .. action,
          }
        end
        plug("mI", "insert_visual", "x")
        plug("mA", "append_visual", "x")
        for lhs, action in pairs({
          ["g="] = "evaluate",
          gx = "exchange",
          gm = "multiply",
          cr = "replace",
          gs = "sort",
          ga = "align",
        }) do
          plug(lhs, action, { "n", "x" })
          plug(lhs .. lhs:sub(-1), action .. "-line", "n")
        end
        return keys
      end)
      require("editing_tools").setup(ctx.opts)
    end,
    id = "editing-tools.nvim",
    source = "Jacky-Lzx/editing-tools.nvim",
    version = "main",
    dev = true,
    main = "editing_tools",
    dependencies = { "motion-tools.nvim" },
    opts = {},
  },
}
