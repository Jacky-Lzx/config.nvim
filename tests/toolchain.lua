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
assert(by_id["parser:regex"] and by_id["mason:codespell"])
assert(by_id["parser:latex"] and by_id["parser:bibtex"])
assert(by_id["system:html_beautify"].optional and by_id["system:fish"].optional)
assert(type(by_id["mason:debugpy"].resolve) == "function")
assert(type(by_id["mason:vue-language-server"].post_install_async) == "function")
assert(by_id["mason:vue-language-server"].post_install == nil)
for _, requirement in ipairs(integration.requirements("mason")) do
  assert(requirement.provider == "mason")
end
assert(not package.loaded.toolchain and not package.loaded.mason and not package.loaded["nvim-treesitter"])

-- Exercise plugin setup and the legacy commands without loading an installer.
local configured, installed
package.loaded.toolchain = {
  setup = function(opts)
    configured = opts
  end,
  install = function(requirements)
    installed = requirements
  end,
}
local spec = require("plugins.coding.toolchain")[1]
spec.config(nil, spec.opts)
assert(configured.concurrency == 2 and type(configured.requirements) == "function")
for command, provider in pairs({ MasonToolsInstall = "mason", TSInstallConfigured = "parser" }) do
  vim.cmd(command)
  assert(#installed > 0)
  for _, requirement in ipairs(installed) do
    assert(requirement.provider == provider)
  end
end
integration.install()
assert(vim.deep_equal(installed, integration.requirements()))
assert(require("plugins.coding.mason")[1].opts.PATH == "append")
assert(require("plugins.coding.treesitter")[1].build == nil, "The legacy installer must not run as a build hook")

-- The actual Vue repair helper must complete every no-op path immediately,
-- and report child-process completion through the queue callback.
local repair = require("languages.vue.compatibility").ensure_typescript5
local directory = assert(vim.env.NVIM_TEST_TMP) .. "/vue-hook"
local typescript = directory .. "/node_modules/@vue/language-server/node_modules/typescript"
local calls, completed, failure = 0, false, nil
local function done(err)
  calls, completed, failure = calls + 1, true, err
end
repair(directory, done, function() end)
assert(completed and failure == nil and calls == 1)
vim.fn.mkdir(typescript, "p")
vim.fn.writefile({ '{"version":"5.9.1"}' }, typescript .. "/package.json")
repair(directory, done, function() end)
assert(calls == 2 and failure == nil)
vim.fn.writefile({ '{"version":"7.0.0"}' }, typescript .. "/package.json")
local system, notify = vim.system, vim.notify
local pending, logs = nil, {}
vim.notify = function() end
vim.system = function(command, opts, callback)
  assert(vim.deep_equal(command, { "npm", "install", "typescript@5", "--no-save", "--no-audit", "--no-fund" }))
  assert(opts.cwd == directory .. "/node_modules/@vue/language-server" and opts.text)
  pending = callback
end
for _, exit_code in ipairs({ 1, 0 }) do
  completed, failure = false, nil
  repair(directory, done, function(chunk)
    logs[#logs + 1] = chunk
  end)
  assert(not completed and pending, "Vue repair must wait for npm")
  pending({ code = exit_code, stdout = "npm output", stderr = "npm stderr" })
  assert(vim.wait(500, function()
    return completed
  end))
  if exit_code == 0 then
    assert(failure == nil)
  else
    assert(failure:find("exit 1", 1, true))
  end
end
vim.system, vim.notify = system, notify
assert(vim.list_contains(logs, "npm output") and vim.list_contains(logs, "npm stderr"))
assert(not package.loaded.mason and not package.loaded["nvim-treesitter"])
print("Toolchain language projection, legacy routes and asynchronous Vue repair checks passed")
