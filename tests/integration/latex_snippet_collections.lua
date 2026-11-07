-- Definition parity and callback coverage without loading the full configuration.
local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(vim.fs.joinpath(require("utils.platform").dev_plugin_root(), "snippet-tools.nvim"))
vim.opt.rtp:prepend(vim.fs.joinpath(require("utils.platform").dev_plugin_root(), "tex-tools.nvim"))
vim.bo.filetype = "tex"
local native = dofile(root .. "/lua/snippet_collections/tex.lua")
local render = require("snippet_tools.render").render
local nodes = require("snippet_tools.nodes")
local context = {
  bufnr = 0,
  filetype = "tex",
  before = "",
  row = 0,
  col = 0,
  selected_text = "",
  match = { captures = { "x" }, start_col = 0 },
  cache = { tex_in_math = false, tex_is_latex = true, tex_in_beamer = false, tex_in_figure = false },
}
for _, entry in ipairs(native) do
  render(nodes.normalize(entry.body), { context = context })
end
assert(
  not package.loaded.luasnip and not package.loaded["luasnip.extras.conditions"],
  "Native collection loads LuaSnip"
)
local conditions = require("snippet_collections.tex.context")
assert(conditions.fn.is_latex())
assert(not package.loaded["luasnip.extras.conditions"], "Shared predicate eagerly loads LuaSnip")

assert(#native > 0, "LaTeX collection is empty")
print("LaTeX collection: " .. #native .. " current callbacks render without a legacy engine")

local engine = require("snippet_tools")
engine.setup({ keymap = false, paths = { root .. "/lua/snippet_collections" } })
local before = #engine.available()
engine.reload()
assert(#engine.available() == before, "Reload duplicates definitions")
engine.reload()
assert(#engine.available() == before, "Repeated reload duplicates definitions")
print("LaTeX collection reload: stable definition count")
