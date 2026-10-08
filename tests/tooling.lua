-- NVIM_CONFIG_ROOT="$PWD" nvim --headless -u NONE -i NONE -l tests/tooling.lua
local root = assert(vim.env.NVIM_CONFIG_ROOT, "NVIM_CONFIG_ROOT is required")
vim.opt.runtimepath:prepend(root)

local formatted
package.loaded.conform = {
  setup = function(opts)
    assert(opts.formatters_by_ft._[1] == "trim_whitespace")
  end,
  format = function(opts)
    formatted = opts
  end,
}
package.loaded.snacks = { toggle = {
  new = function()
    return { map = function() end }
  end,
} }
local conform = require("plugins.coding.conform")[1]
vim.g.enable_autoformat = false
conform.config(nil, vim.deepcopy(conform.opts))
assert(vim.g.enable_autoformat == false, "preserve explicit autoformat preference")
vim.g.enable_autoformat = nil
conform.config(nil, vim.deepcopy(conform.opts))
assert(vim.g.enable_autoformat == true)
local buf = vim.api.nvim_get_current_buf()
assert(conform.opts.format_on_save(buf).lsp_format == "fallback")
vim.b[buf].disable_autoformat = true
assert(conform.opts.format_on_save(buf) == nil)
vim.b[buf].disable_autoformat = nil
vim.b[buf].enable_autoformat = false
assert(conform.opts.format_on_save(buf) == nil)
vim.b[buf].enable_autoformat = nil
conform.keys[1][2]()
assert(formatted.lsp_format == "fallback")
local schedule = vim.schedule
vim.schedule = function() end
dofile(root .. "/lua/config/lsp.lua")
vim.schedule = schedule
vim.api.nvim_exec_autocmds("LspAttach", { buffer = buf, data = { client_id = 1 } })
vim.api.nvim_buf_call(buf, function()
  vim.fn.maparg("<leader>gf", "n", false, true).callback()
end)
assert(formatted.bufnr == buf and formatted.lsp_format == "fallback")

local function buffer(ft, text, scratch)
  local b = vim.api.nvim_create_buf(true, scratch or false)
  vim.bo[b].filetype = ft
  vim.api.nvim_buf_set_lines(b, 0, -1, false, { text or "word" })
  return b
end
vim.bo[buf].filetype = "lua"
local relevant = buffer("lua")
local unrelated = buffer("python")
local huge = buffer("lua", string.rep("x", 1024 * 1024 + 1))
local special = buffer("lua", nil, true)
local unloaded = buffer("lua")
vim.api.nvim_buf_delete(unloaded, { unload = true, force = true })
local selected = require("plugins.coding.completion.core")[1].opts.sources.providers.buffer.opts.get_bufnrs()
assert(vim.list_contains(selected, buf) and vim.list_contains(selected, relevant))
for _, b in ipairs({ unrelated, huge, special, unloaded }) do
  assert(not vim.list_contains(selected, b), "exclude irrelevant, huge, special, and unloaded buffers")
end

local calls, available, typos = {}, true, false
package.loaded.lint = {
  linters = {},
  try_lint = function(name)
    calls[#calls + 1] = { name = name, buf = vim.api.nvim_get_current_buf() }
  end,
}
local executable, clients = vim.fn.executable, vim.lsp.get_clients
vim.fn.executable = function(name)
  assert(name == "codespell")
  return available and 1 or 0
end
vim.lsp.get_clients = function(opts)
  assert(opts.name == "typos_lsp" and opts.bufnr == relevant)
  return typos and { {} } or {}
end
local lint = require("plugins.coding.nvim-lint")[1]
lint.config(nil, lint.opts)
local function lint_buffer(b)
  calls = {}
  vim.api.nvim_exec_autocmds("BufWritePost", { buffer = b })
  return #calls
end
assert(lint_buffer(relevant) == 2 and calls[2].name == "codespell" and calls[2].buf == relevant)
typos = true
assert(lint_buffer(relevant) == 1)
typos, available = false, false
assert(lint_buffer(relevant) == 1)
assert(lint_buffer(huge) == 0 and lint_buffer(special) == 0)
assert(lint_buffer(buffer("")) == 0)
vim.fn.executable, vim.lsp.get_clients = executable, clients

local function definition(language)
  return require("languages." .. language)
end
local function has_tool(language, mason)
  for _, tool in ipairs(definition(language).tools) do
    if tool.mason == mason then
      return true
    end
  end
  return false
end
for _, language in ipairs({ "vue", "yaml" }) do
  assert(has_tool(language, "prettierd"))
end
assert(vim.list_contains(definition("toml").parsers, "toml"))
assert(vim.list_contains(definition("swift").parsers, "swift"))
assert(vim.deep_equal(definition("swift").formatters.swift, { "swift" }))
assert(vim.deep_equal(definition("swift").linters.swift, { "swiftlint" }))
local swift_dap = require("languages.swift.plugins")[1].opts
assert(swift_dap.configurations.swift[1].type == "lldb")
assert(swift_dap.adapters.lldb.command == (vim.fn.has("mac") == 1 and "xcrun" or "lldb-dap"))
assert(not has_tool("python", "pyright"))
assert(not has_tool("vue", "typescript-language-server"))
local formats = definition("verilog").formatters
assert(vim.deep_equal(formats.verilog, formats.systemverilog))
local linters = definition("verilog").linters
assert(vim.deep_equal(linters.verilog, linters.systemverilog))
dofile(root .. "/filetype.lua")
for _, filename in ipairs({ "test.zsh", ".zshrc", ".zshenv" }) do
  assert(vim.filetype.match({ filename = filename }) == "zsh")
end
assert(vim.filetype.match({ filename = "test.sh", buf = buffer("", "#!/bin/zsh") }) == "zsh")
assert(definition("bash").formatters.zsh == nil)
print("Tooling regression tests passed")
