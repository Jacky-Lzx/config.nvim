local root = assert(vim.env.NVIM_CONFIG_ROOT, "NVIM_CONFIG_ROOT is required")
vim.opt.runtimepath:prepend(root)

for name, kind in vim.fs.dir(root, { depth = math.huge }) do
  if kind == "file" and name:match("%.lua$") then
    assert(loadfile(root .. "/" .. name), name)
  end
end

local platform = require("config.platform")
assert(platform.os == "macos" or platform.os == "linux" or platform.os == "other")
assert(type(platform.open) == "function")

local languages = require("languages")
local function selection(profiles, debugging)
  return { profiles = profiles, features = { debugging = debugging == true } }
end
local before = #vim.api.nvim_get_autocmds({})
local base = languages.resolve(selection({ "base" }))
assert(vim.list_contains(base.names, "lua"))
assert(not vim.list_contains(base.names, "java"))
assert(vim.list_contains(base.servers, "lua_ls"))
assert(not vim.list_contains(base.servers, "jdtls"))
-- A language without a server must never be passed to vim.lsp.enable.
assert(not vim.list_contains(base.servers, "kdl"))
assert(vim.deep_equal(base, languages.resolve(selection({ "base", "base" }))))
assert(next(languages.resolve(selection({})).servers) == nil)
local ok, err = pcall(languages.resolve, selection({ "typo" }))
assert(not ok and tostring(err):find("Unknown language profile: typo", 1, true))

local native = languages.resolve(selection({ "native" }))
assert(vim.list_contains(native.names, "swift"))
assert(vim.list_contains(native.servers, "sourcekit"))

local optional = languages.resolve(selection({ "optional" }))
assert(vim.list_contains(optional.names, "java"))
assert(vim.list_contains(optional.servers, "jdtls"))
assert(vim.deep_equal(optional.linters.verilog, { "iverilog" }))

local python = languages.resolve(selection({ "data" }))
assert(vim.deep_equal(python.servers, { "basedpyright" }))
assert(vim.deep_equal(python.formatters.python, { "ruff_fix", "ruff_organize_imports", "ruff_format" }))
assert(vim.deep_equal(python.linters.python, { "ruff" }))
for _, tool in ipairs(python.tools) do
  assert(tool.mason ~= "debugpy")
end
local debug = languages.resolve(selection({ "data", "native" }, true))
local tools = {}
for _, tool in ipairs(debug.tools) do
  if tool.mason then
    assert(not tools[tool.mason], "Duplicate Mason package: " .. tool.mason)
    tools[tool.mason] = tool
  end
end
assert(tools.debugpy and tools.codelldb)
assert(type(tools.debugpy.resolve) == "function")

local writing = languages.resolve(selection({ "writing" }))
assert(vim.list_contains(writing.servers, "texlab"))
assert(vim.list_contains(writing.parsers, "latex"))
assert(vim.deep_equal(writing.formatters.tex, { "tex-fmt" }))
assert(vim.deep_equal(writing.linters.tex, { "chktex" }))
assert(#vim.api.nvim_get_autocmds({}) == before, "Reading language metadata registered autocmds")
assert(vim.g.tex_flavor == nil, "Reading language metadata changed globals")

-- A system requirement in an earlier profile must not hide a managed package later.
local combined = languages.resolve(selection({ "base", "web", "writing" }))
local managed = {}
for _, tool in ipairs(combined.tools) do
  if tool.mason then
    managed[tool.mason] = true
  end
end
assert(managed.prettierd and managed.prettier)
local isolated = languages.resolve(selection({ "data" }))
isolated.formatters.python[1] = "changed"
assert(languages.resolve(selection({ "data" })).formatters.python[1] == "ruff_fix")

local specs = require("config.specs")
local ok_feature, feature_err = pcall(specs.build, { profiles = {}, features = { typo = true } })
assert(not ok_feature and tostring(feature_err):find("Unknown feature: typo", 1, true))
assert(not package.loaded.lazy, "Registry tests unexpectedly loaded lazy.nvim")
print("Syntax and language profile checks passed")
vim.cmd("quitall!")
