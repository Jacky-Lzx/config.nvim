return {
  {
    "echasnovski/mini.operators",
    version = "*",
    keys = function()
      local keys = {}
      -- Preserve MiniOperators' native URI fallback before Lazy replaces gx.
      local uri = vim.fn.maparg("gx", "n", false, true)
      if vim.fn.maparg("gX", "n") == "" and (uri.desc or ""):find("URI under cursor", 1, true) then
        keys[#keys + 1] = { "gX", uri.callback or uri.rhs, desc = uri.desc }
      end
      for _, prefix in ipairs({ "g=", "gx", "gm", "cr", "gs" }) do
        keys[#keys + 1] = { prefix, mode = { "n", "x" } }
        keys[#keys + 1] = { prefix .. prefix:sub(-1), mode = "n" }
      end
      return keys
    end,
    opts = {
      replace = { prefix = "cr" },
    },
  },
}
