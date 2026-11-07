-- Use the actual sibling plugin and an offline npm fixture. Failed installs
-- must not publish a partially initialized package.
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
local script = temp .. "/npm_fixture.py"
vim.fn.writefile(
  vim.split(
    [=[
import json, os, pathlib, sys
root = pathlib.Path.cwd()
manifest = json.loads((root / "package.json").read_text())
assert manifest["overrides"]["typescript"] == manifest["dependencies"]["typescript"] == "6.0.3"
print("fixture npm output")
print("fixture npm stderr", file=sys.stderr)
status = int(pathlib.Path(os.environ["CONFIG_TEST_NPM_STATUS"]).read_text())
if status:
    raise SystemExit(status)
(root / "node_modules/.bin").mkdir(parents=True)
(root / "node_modules/@vue/language-server").mkdir(parents=True)
binary = root / "node_modules/.bin/vue-language-server"
binary.write_text("#!/bin/sh\nexit 0\n")
binary.chmod(0o755)
(root / "package-lock.json").write_text(json.dumps({"lockfileVersion": 3, "packages": {}}))
]=],
    "\n",
    { plain = true }
  ),
  script
)
vim.fn.writefile({ "#!/bin/sh", "exec python3 " .. vim.fn.shellescape(script) .. ' "$@"' }, temp .. "/bin/npm")
assert(vim.uv.fs_chmod(temp .. "/bin/npm", 493))
vim.env.PATH = temp .. "/bin:" .. vim.env.PATH
local requirement
for _, entry in ipairs(require("integrations.toolchain").requirements("tool")) do
  if entry.name == "vue-language-server" then
    requirement = vim.deepcopy(entry)
  end
end
assert(requirement and not requirement.post_install_async)
requirement.executable = nil
local recipe = tools.definition("vue-language-server", true)
local tc = require("toolchain")
tc.setup({
  requirements = { requirement },
  notify = false,
  log_file = temp .. "/events.jsonl",
  tools = { install_dir = temp .. "/store", sources = { ["vue-language-server"] = recipe } },
})
vim.fn.writefile({ "9" }, status_file)
tc.install()
assert(tc.wait(5000))
local task = tc.status()[1]
assert(task.state == "failed", vim.inspect(task))
assert(table.concat(task.logs, "\n"):find("fixture npm stderr", 1, true))
assert(tools.path("vue-language-server") == nil)
vim.fn.writefile({ "0" }, status_file)
tc.retry()
assert(tc.wait(5000))
task = tc.status()[1]
assert(task.state == "installed" and task.attempt == 2, vim.inspect(task))
assert(table.concat(task.logs, "\n"):find("fixture npm output", 1, true))
assert(tools.info("vue-language-server").intact)
local resources = require("toolchain.resources")
local expected = resources.npm_package("vue-language-server", "@vue/language-server")
  or tools.path("vue-language-server", "server")
assert(resources.resolve("vue-language-server", "server") == expected)
tc.install()
assert(tc.wait(5000) and tc.status()[1].state == "skipped")
assert(not package.loaded.mason and not package.loaded["mason-registry"])
print("Independent Vue recipe: pinned overrides, subprocess failure, atomic publication, retry and intact reuse passed")
