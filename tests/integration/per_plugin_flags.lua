local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(assert(vim.env.NVIM_PLUGIN_TOOLS_PATH))
local resolve = require("plugin_tools.graph").resolve
local build = require("config.specs").build
local function graph()
  return resolve(build(), { dev = { path = require("utils.platform").dev_plugin_root(), fallback = true } })
end
local function names(value, excluded_owner)
  local result = {}
  for id, node in pairs(value.nodes) do
    if node.owner ~= excluded_owner then
      result[#result + 1] = id
    end
  end
  table.sort(result)
  return result
end
local baseline = graph()
for _, module in ipairs({
  "plugins.coding.format-tools",
  "languages.rust.crates",
  "languages.markdown.peek",
  "languages.markdown.render-markdown",
}) do
  local spec = require(module)[1]
  local original = spec.enabled
  for _, enabled in ipairs({ false, true }) do
    spec.enabled = enabled
    local changed = graph()
    assert((changed.nodes[spec.id] ~= nil) == enabled, "Plugin flag did not control its declaration: " .. spec.id)
    assert(vim.deep_equal(names(changed, spec.id), names(baseline, spec.id)), "Flag changed unrelated owners")
  end
  spec.enabled = original
  assert(vim.deep_equal(names(graph()), names(baseline)), "Restoring a flag changed the graph")
end
local markdown = require("languages.markdown.plugins")[1]
local original = markdown.enabled
markdown.enabled = false
local disabled = graph()
for _, id in ipairs({ "markdown-tools.nvim", "render-markdown.nvim", "peek.nvim" }) do
  assert(not disabled.nodes[id] and not disabled.packages[id], "Disabling Markdown retained its subtree: " .. id)
end
markdown.enabled = original
assert(vim.deep_equal(names(graph()), names(baseline)), "Restoring Markdown changed the graph")
print("Per-plugin flags: enabled/disabled behavior and independent restoration follow current defaults")
