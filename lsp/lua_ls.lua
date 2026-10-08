local markers = { { ".luarc.json", ".luarc.jsonc" }, ".git" }
local log = vim.fs.joinpath(vim.fn.stdpath("state"), "lsp", "lua_ls", "log")
local meta = vim.fs.joinpath(vim.fn.stdpath("cache"), "lsp", "lua_ls", "meta")
vim.fn.mkdir(log, "p")
vim.fn.mkdir(meta, "p")

return {
  cmd = { "lua-language-server", "--logpath=" .. log, "--metapath=" .. meta },
  filetypes = { "lua" },
  root_markers = markers,
  root_dir = function(buffer, on_dir)
    local root = require("features.lsp").root(buffer, markers)
    if root then
      on_dir(root)
    end
  end,
  settings = { Lua = { workspace = { checkThirdParty = false }, telemetry = { enable = false } } },
  before_init = function(_, config)
    local root = config.root_dir
    if root ~= vim.fn.stdpath("config") then
      return
    end
    for _, file in ipairs({ ".luarc.json", ".luarc.jsonc" }) do
      if vim.fn.filereadable(vim.fs.joinpath(root, file)) == 1 then
        return
      end
    end
    config.settings.Lua = vim.tbl_deep_extend("force", config.settings.Lua, {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace = { library = { vim.env.VIMRUNTIME } },
    })
  end,
}
