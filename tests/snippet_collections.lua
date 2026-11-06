-- Validate today's collections without freezing the pre-migration inventory.
local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(require("utils.platform").dev_plugin_root() .. "/snippet-tools.nvim")
local engine = require("snippet_tools")
local render, nodes = require("snippet_tools.render").render, require("snippet_tools.nodes")
local registry = require("snippet_tools.registry")
local count, collections = 0, 0
for name, kind in vim.fs.dir(root .. "/lua/snippet_collections") do
  local ft = name:match("^(.*)%.lua$")
  if kind == "file" and ft and ft ~= "helpers" then
    local entries = dofile(root .. "/lua/snippet_collections/" .. name)
    assert(vim.islist(entries), "Collection must be a list: " .. name)
    registry.add(ft, entries)
    collections = collections + 1
    vim.bo.filetype, vim.bo.commentstring = ft, "-- %s"
    local context = engine.context()
    context.match = { captures = { "x" }, start_col = 0 }
    context.cache = { tex_in_math = false, tex_is_latex = ft == "tex", tex_in_beamer = false, tex_in_figure = false }
    for _, entry in ipairs(entries) do
      context.match.captures = ft == "markdown" and entry.pattern and { "3", "2" } or { "x" }
      local ok, result = pcall(render, nodes.normalize(entry.body), { context = context })
      assert(ok and type(result.text) == "string", name .. ": " .. entry.trigger .. ": " .. tostring(result))
      count = count + 1
    end
  end
end
assert(collections > 0 and count > 0, "No personal snippet collections found")
for name in pairs(package.loaded) do
  assert(not name:match("^luasnip"), "Unexpected legacy module: " .. name)
end
print(
  "Current snippet collections: " .. collections .. " collections, " .. count .. " definitions validated and rendered"
)
