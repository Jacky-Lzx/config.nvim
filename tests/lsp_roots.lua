local ok, err = xpcall(function()
  local lsp = require("features.lsp")
  assert(not vim.lsp.is_enabled("lua_ls"))
  assert(vim.fn.exists(":ConfigLspInfo") == 0)
  assert(not lsp.root(0, { ".git" }))
  local project = vim.env.NVIM_TEST_TMP .. "/roots"
  local nested = project .. "/nested"
  vim.fn.mkdir(project .. "/.git", "p")
  vim.fn.mkdir(nested, "p")
  vim.fn.writefile({ "{}" }, nested .. "/.luarc.json")
  local buffer = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buffer, nested .. "/test.lua")
  assert(vim.lsp.config._configs.lua_ls == nil)
  local declaration = assert(vim.lsp.config.lua_ls)
  assert(declaration.cmd[1] == "lua-language-server" and declaration.filetypes[1] == "lua")
  local markers = declaration.root_markers
  assert(lsp.root(buffer, markers) == nested)
  vim.fn.delete(nested .. "/.luarc.json")
  assert(lsp.root(buffer, markers) == project)
  vim.fn.delete(project .. "/.git", "d")
  assert(lsp.root(buffer, markers) == nested)
  vim.bo[buffer].buftype = "nofile"
  assert(lsp.root(buffer, markers) == nil)
  local own = { root_dir = vim.fn.stdpath("config"), settings = vim.deepcopy(declaration.settings) }
  declaration.before_init({}, own)
  assert(own.settings.Lua.runtime.version == "LuaJIT")
  assert(vim.list_contains(own.settings.Lua.diagnostics.globals, "vim"))
  assert(vim.list_contains(own.settings.Lua.workspace.library, vim.env.VIMRUNTIME))
  local other = { root_dir = nested, settings = vim.deepcopy(declaration.settings) }
  declaration.before_init({}, other)
  assert(other.settings.Lua.runtime == nil and other.settings.Lua.diagnostics == nil)
  local config_file = vim.fn.stdpath("config") .. "/.luarc.json"
  vim.fn.writefile({ "{}" }, config_file)
  local configured = { root_dir = vim.fn.stdpath("config"), settings = vim.deepcopy(declaration.settings) }
  declaration.before_init({}, configured)
  assert(configured.settings.Lua.runtime == nil and configured.settings.Lua.workspace.library == nil)
  vim.fn.delete(config_file)
  io.stdout:write("LSP roots checks: 10 passed\n")
  io.stdout:flush()
end, debug.traceback)
if not ok then
  print(err)
  vim.cmd.cquit()
end
vim.cmd.qa({ bang = true })
