return {
  cmd = { "verible-verilog-ls", "--rules_config_search" },

  -- root_dir = function(fname)
  --   -- return vim.fs.dirname(vim.fs.find(".git", { path = fname, upward = true })[1])
  --   -- print(vim.fs.dirname(fname))
  --   return vim.fs.dirname(fname)
  -- end,

  -- root_dir = function(fname)
  --   return vim.fs.dirname(vim.fn.getcwd())
  -- end,
}
