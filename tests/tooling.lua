-- NVIM_CONFIG_ROOT="$PWD" nvim --headless -u NONE -i NONE -l tests/tooling.lua
local root = assert(vim.env.NVIM_CONFIG_ROOT, "NVIM_CONFIG_ROOT is required")
vim.opt.runtimepath:prepend(root)

local formatted
package.loaded.format_tools = {
  setup = function(opts)
    assert(opts.formatters_by_ft._[1] == "trim_whitespace")
  end,
  format = function(opts)
    formatted = opts
  end,
}
local format_registration
package.loaded.keymap_tools = {
  register_toggle = function(source, spec)
    assert(source == "config.toggle.autoformat")
    format_registration = {
      get = function()
        return spec.get({ win = vim.api.nvim_get_current_win() })
      end,
    }
    return function()
      spec.set(not format_registration.get())
    end, format_registration
  end,
}
package.preload.snacks = function()
  error("Formatting must not load Snacks")
end
local formatter = require("plugins.coding.format-tools")[1]
vim.g.enable_autoformat = false
formatter.config({ opts = vim.deepcopy(formatter.opts), dir = formatter.dir })
assert(vim.g.enable_autoformat == false, "preserve explicit autoformat preference")
vim.g.enable_autoformat = nil
formatter.config({ opts = vim.deepcopy(formatter.opts), dir = formatter.dir })
local toggle_format = vim.fn.maparg("<leader>tf", "n", false, true).callback
toggle_format()
assert(vim.g.enable_autoformat == false, "Allow disabling formatting before the first save")
assert(not format_registration.get())
assert(vim.fn.maparg("<leader>tf", "n", false, true).callback == toggle_format, "Inspection replaced the owner mapping")
assert(not package.loaded.snacks)
toggle_format()
assert(vim.g.enable_autoformat == true)
local buf = vim.api.nvim_get_current_buf()
assert(formatter.opts.format_on_save(buf).lsp_format == "fallback")
vim.b[buf].disable_autoformat = true
assert(formatter.opts.format_on_save(buf) == nil)
vim.b[buf].disable_autoformat = nil
vim.b[buf].enable_autoformat = false
assert(formatter.opts.format_on_save(buf) == nil)
vim.b[buf].enable_autoformat = nil
require("config.bindings").entries[formatter.id][1][2]()
assert(formatted.lsp_format == "fallback")
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
local selected = require("plugins.coding.completion.core")[1].opts.buffer.get_bufnrs()
assert(vim.list_contains(selected, buf) and vim.list_contains(selected, relevant))
for _, b in ipairs({ unrelated, huge, special, unloaded }) do
  assert(not vim.list_contains(selected, b), "exclude irrelevant, huge, special, and unloaded buffers")
end

local configured, typos = nil, false
package.loaded.lint_tools = {
  setup = function(opts)
    configured = opts
  end,
}
local clients = vim.lsp.get_clients
vim.lsp.get_clients = function(opts)
  assert(opts.name == "typos_lsp" and opts.bufnr == relevant)
  return typos and { {} } or {}
end
local lint = require("plugins.coding.lint-tools")[1]
lint.config({ opts = lint.opts, dir = lint.dir })
assert(configured == lint.opts)
assert(configured.extra_linters[1] == "codespell")
assert(vim.deep_equal(configured.linters_by_ft, require("languages").current().linters))
assert(configured.linters.codespell.condition({ bufnr = relevant }))
typos = true
assert(not configured.linters.codespell.condition({ bufnr = relevant }))
vim.lsp.get_clients = clients

local function definition(language)
  return require("languages." .. language)
end
local function has_tool(language, package_name)
  for _, tool in ipairs(definition(language).tools) do
    if tool.package == package_name then
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
local swift_dap = require("plugins.disabled.nvim-dap.swift")[1].opts
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
