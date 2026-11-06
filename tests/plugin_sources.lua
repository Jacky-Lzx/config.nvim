local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(assert(vim.env.NVIM_PLUGIN_TOOLS_PATH))
require("config.context").initialize({
  profiles = { "base", "data", "writing" },
  features = { tasks = true, sessions = true },
})
local resolve = require("plugin_tools.graph").resolve
local published = {
  "completion-tools.nvim",
  "debug-tools.nvim",
  "editing-tools.nvim",
  "file-tools.nvim",
  "git-tools.nvim",
  "image-tools.nvim",
  "input-tools.nvim",
  "keymap-tools.nvim",
  "lsp-tools.nvim",
  "motion-tools.nvim",
  "notification-tools.nvim",
  "pairs.nvim",
  "selection-tools.nvim",
  "snippet-tools.nvim",
  "task-tools.nvim",
  "tex-tools.nvim",
  "theme-tools.nvim",
  "toolchain-tools.nvim",
  "ui-tools.nvim",
  "workspace-tools.nvim",
}
local all_specs = require("config.specs").build()
local development_root = require("utils.platform").dev_plugin_root()
local installed_root = vim.env.NVIM_TEST_TMP .. "/packages"
for _, format in ipairs({ "https://github.com/%s.git", "git@github.com:%s.git" }) do
  local development = resolve(all_specs, {
    url_format = format,
    dev = { path = development_root, fallback = true },
  })
  local fallback = resolve(all_specs, {
    url_format = format,
    root = installed_root,
    dev = { path = vim.env.NVIM_TEST_TMP .. "/missing", fallback = true },
  })
  -- Third-party packages and personal plugins must follow the same template.
  for id, package in pairs(development.packages) do
    local source = development.nodes[id].source
    if source then
      assert(source:match("^[%w_.-]+/[%w_.-]+$"), "Expected owner/repo source: " .. id)
      assert(package.source == format:format(source), id)
      assert(fallback.packages[id].source == package.source, id)
    end
  end
  for _, id in ipairs(published) do
    local node, package = development.nodes[id], development.packages[id]
    assert(node.source == "Jacky-Lzx/" .. id, id)
    assert(node.version == "main" and package.version == "main", id)
    assert(node.dev and not package.managed and node.dir == development_root .. "/" .. id, id)
    assert(fallback.packages[id].managed and fallback.packages[id].source == package.source, id)
    assert(fallback.nodes[id].dir == installed_root .. "/" .. id, id)
  end
  assert(fallback.nodes["workspace-tools.python"].owner == "workspace-tools.nvim")
  assert(fallback.nodes["workspace-tools.python"].dir == fallback.nodes["workspace-tools.nvim"].dir)
end
assert(not package.loaded["config.bindings"], "Resolving sources must not initialize plugins")
print("GitHub shorthand sources: shared HTTPS/SSH templates, local development preference and managed fallbacks passed")
