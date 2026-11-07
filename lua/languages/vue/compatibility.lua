-- The config owns server composition; toolchain owns package locations.
local M = {}
M.filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" }
function M.server_path()
  return require("toolchain.resources").resolve("vue-language-server", "server")
end
return M
