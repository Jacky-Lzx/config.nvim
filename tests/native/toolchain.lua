local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
require("config.context").initialize({
  profiles = { "base", "web", "native", "data", "writing" },
  features = { debugging = true },
})
local integration = require("integrations.toolchain")
local by_id = {}
for _, requirement in ipairs(integration.requirements()) do
  by_id[requirement.provider .. ":" .. requirement.name] = requirement
end
assert(by_id["parser:regex"] and by_id["tool:codespell"])
assert(by_id["parser:latex"] and by_id["parser:bibtex"])
assert(by_id["system:html_beautify"].optional and by_id["system:fish"].optional)
assert(type(by_id["tool:debugpy"].resolve) == "function")
assert(by_id["tool:vue-language-server"].post_install_async == nil)
assert(by_id["tool:vue-language-server"].post_install == nil)
for _, requirement in ipairs(integration.requirements("tool")) do
  assert(requirement.provider == "tool")
end
assert(not package.loaded.toolchain and not package.loaded.mason and not package.loaded["nvim-treesitter"])

-- Exercise plugin setup and the legacy commands without loading an installer.
local configured, installed, opened
package.loaded.toolchain = {
  setup = function(opts)
    configured = opts
  end,
  open = function()
    opened = true
  end,
  install = function(requirements)
    installed = requirements
  end,
}
local spec = require("plugins.coding.toolchain")[1]
spec.config({ opts = spec.opts, dir = spec.dir })
assert(configured.concurrency == 2 and type(configured.requirements) == "function")
vim.cmd("Mason")
assert(opened and installed == nil, "Mason compatibility must only open the manager")
for command, provider in pairs({ MasonToolsInstall = "tool", TSInstallConfigured = "parser" }) do
  vim.cmd(command)
  assert(#installed > 0)
  for _, requirement in ipairs(installed) do
    assert(requirement.provider == provider)
  end
end
integration.install()
assert(vim.deep_equal(installed, integration.requirements()))
assert(spec.opts.tools.path == "append")
assert(spec.opts.tools.sources == nil, "Shared package recipes belong in the toolchain registry")
assert(spec.opts.tools.lockfile == root .. "/toolchain-lock.json")
assert(not spec.dependencies, "Toolchain must not depend on the legacy runtimes")

assert(not package.loaded["toolchain.tool_installers"])
print("Toolchain language projection and legacy routes stay cold; npm compatibility belongs to recipes")
