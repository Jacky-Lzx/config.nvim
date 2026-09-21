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
local conform = require("plugins.core.conform")[1]
vim.g.enable_autoformat = false
conform.config(nil, {})
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
dofile(root .. "/after/plugin/lsp.lua")
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
local selected = require("plugins.core.blink")[1].opts.sources.providers.buffer.opts.get_bufnrs()
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
local lint = require("plugins.core.nvim-lint")[1]
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

local function spec(language, plugin)
  for _, entry in ipairs(require("plugins.languages." .. language)) do
    if entry[1] == plugin then
      return entry
    end
  end
  error("missing " .. plugin .. " in " .. language)
end
for _, language in ipairs({ "vue", "yaml" }) do
  assert(vim.list_contains(spec(language, "mason-org/mason.nvim").opts.ensure_installed, "prettierd"))
end
assert(vim.list_contains(spec("toml", "nvim-treesitter/nvim-treesitter").opts.ensure_installed, "toml"))
assert(vim.list_contains(spec("swift", "nvim-treesitter/nvim-treesitter").opts.ensure_installed, "swift"))
assert(vim.deep_equal(spec("swift", "stevearc/conform.nvim").opts.formatters_by_ft.swift, { "swift" }))
assert(vim.deep_equal(spec("swift", "mfussenegger/nvim-lint").opts.linters_by_ft.swift, { "swiftlint" }))
local swift_dap = spec("swift", "mfussenegger/nvim-dap").opts
assert(swift_dap.configurations.swift[1].type == "lldb")
assert(swift_dap.adapters.lldb.command == (vim.fn.has("mac") == 1 and "xcrun" or "lldb-dap"))
assert(not vim.list_contains(spec("python", "mason-org/mason.nvim").opts.ensure_installed, "pyright"))
assert(not vim.list_contains(spec("vue", "mason-org/mason.nvim").opts.ensure_installed, "typescript-language-server"))
local formats = spec("verilog", "stevearc/conform.nvim").opts.formatters_by_ft
assert(vim.deep_equal(formats.verilog, formats.systemverilog))
package.loaded["lint.parser"] = {
  from_pattern = function()
    return function() end
  end,
}
local linters = spec("verilog", "mfussenegger/nvim-lint").opts(nil, {}).linters_by_ft
assert(vim.deep_equal(linters.verilog, linters.systemverilog))
dofile(root .. "/filetype.lua")
for _, filename in ipairs({ "test.zsh", ".zshrc", ".zshenv" }) do
  assert(vim.filetype.match({ filename = filename }) == "zsh")
end
assert(vim.filetype.match({ filename = "test.sh", buf = buffer("", "#!/bin/zsh") }) == "zsh")
assert(spec("bash", "stevearc/conform.nvim").opts.formatters_by_ft.zsh == nil)
print("Tooling regression tests passed")
