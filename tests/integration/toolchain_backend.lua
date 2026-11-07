-- Use the actual sibling plugin and an offline recipe. Vue repair runs a real
-- subprocess; failed hooks must not publish a partially repaired installation.
local root = assert(vim.env.NVIM_CONFIG_ROOT)
local temp = assert(vim.env.NVIM_TEST_TMP) .. "/toolchain-backend"
vim.opt.rtp:prepend(root)
vim.opt.rtp:append(require("utils.platform").dev_plugin_root() .. "/toolchain-tools.nvim")
local tools = require("toolchain.tools")
tools.setup()
local bundled = tools.definition("ltex-ls-plus", true)
local lock = vim.json.decode(table.concat(vim.fn.readfile(root .. "/toolchain-lock.json"), "\n"))
local target = require("toolchain.tool_installers").target()
local locked = lock.targets[target] and lock.targets[target].packages["ltex-ls-plus"]
assert(bundled.version == "18.7.0" and bundled.bin["ltex-ls-plus"])
if locked then
  assert(vim.deep_equal(bundled, locked.recipe), "Registry migration changed the locked LTeX+ recipe")
end
vim.fn.mkdir(temp .. "/bin", "p")
local status_file = temp .. "/exit-code"
vim.env.CONFIG_TEST_NPM_STATUS = status_file
vim.fn.writefile({
  "#!/bin/sh",
  "echo 'fixture npm output'",
  "echo 'fixture npm stderr' >&2",
  'exit "$(cat "$CONFIG_TEST_NPM_STATUS")"',
}, temp .. "/bin/npm")
assert(vim.uv.fs_chmod(temp .. "/bin/npm", 493))
vim.env.PATH = temp .. "/bin:" .. vim.env.PATH
local fixture = temp .. "/install.sh"
vim.fn.writefile({
  "#!/bin/sh",
  'mkdir -p "$1/node_modules/@vue/language-server/node_modules/typescript" "$1/libexec"',
  [[printf '%s\n' '{"version":"7.0.0"}' > "$1/node_modules/@vue/language-server/node_modules/typescript/package.json"]],
  [[printf '#!/bin/sh\nexit 0\n' > "$1/libexec/server"]],
}, fixture)
local requirement
for _, entry in ipairs(require("integrations.toolchain").requirements("tool")) do
  if entry.name == "vue-language-server" then
    requirement = vim.deepcopy(entry)
  end
end
assert(requirement and requirement.post_install_async)
requirement.executable = nil
local tc = require("toolchain")
tc.setup({
  requirements = { requirement },
  notify = false,
  log_file = temp .. "/events.jsonl",
  tools = {
    install_dir = temp .. "/store",
    sources = {
      ["vue-language-server"] = {
        kind = "commands",
        version = "1.0.0",
        commands = { { "sh", fixture, "{root}" } },
        bin = { ["vue-language-server"] = { path = "libexec/server" } },
      },
    },
  },
})
vim.fn.writefile({ "9" }, status_file)
tc.install()
assert(tc.wait(5000))
local task = tc.status()[1]
assert(task.state == "failed", vim.inspect(task))
assert(task.message:find("exit 9", 1, true), task.message)
assert(table.concat(task.logs, "\n"):find("fixture npm stderr", 1, true))
assert(require("toolchain.tools").path("vue-language-server") == nil)
vim.fn.writefile({ "0" }, status_file)
tc.retry()
assert(tc.wait(5000))
task = tc.status()[1]
assert(task.state == "installed" and task.attempt == 2, vim.inspect(task))
assert(table.concat(task.logs, "\n"):find("fixture npm output", 1, true))
assert(require("toolchain.tools").info("vue-language-server").intact)
tc.install()
assert(tc.wait(5000) and tc.status()[1].state == "skipped")
assert(not package.loaded.mason and not package.loaded["mason-registry"])
print("Independent tools and Vue hook: subprocess failure, atomic publication, retry and intact reuse passed")
