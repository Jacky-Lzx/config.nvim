-- Use the actual sibling plugin and Mason, with a disposable registry/package
-- and a local npm fixture. The real Vue repair helper must report child errors.
local root = assert(vim.env.NVIM_CONFIG_ROOT)
local temp = assert(vim.env.NVIM_TEST_TMP) .. "/toolchain-backend"
vim.opt.rtp:prepend(root)
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/mason.nvim")
vim.opt.rtp:append(require("utils.platform").dev_plugin_root() .. "/toolchain-tools.nvim")
vim.fn.mkdir(temp .. "/bin", "p")
vim.fn.mkdir(vim.fn.stdpath("state"), "p")
local status_file = temp .. "/exit-code"
vim.env.CONFIG_TEST_NPM_STATUS = status_file
vim.fn.writefile({
  "#!/bin/sh",
  "printf 'fixture npm output\\n'",
  "printf 'fixture npm stderr\\n' >&2",
  'exit "$(cat "$CONFIG_TEST_NPM_STATUS")"',
}, temp .. "/bin/npm")
assert(vim.uv.fs_chmod(temp .. "/bin/npm", 493))
vim.env.PATH = temp .. "/bin:" .. vim.env.PATH
assert(vim.fn.exepath("npm") == temp .. "/bin/npm")

local installs = 0
package.preload["config-toolchain-test.registry"] = function()
  return { vue = "config-toolchain-test.package" }
end
package.preload["config-toolchain-test.package"] = function()
  return {
    schema = "registry+v1",
    name = "vue-language-server",
    description = "Offline Vue repair test fixture",
    homepage = "https://example.invalid",
    licenses = { "MIT" },
    languages = {},
    categories = {},
    source = {
      id = "pkg:mason/vue-language-server@1.0.0",
      install = function(ctx)
        installs = installs + 1
        local path = "node_modules/@vue/language-server/node_modules/typescript"
        ctx.fs:mkdirp(path)
        ctx.fs:write_file(path .. "/package.json", '{"version":"7.0.0"}')
      end,
    },
  }
end
require("mason").setup({
  install_root_dir = temp .. "/mason",
  PATH = "append",
  registries = { "lua:config-toolchain-test.registry" },
  system_registries = {},
})
local requirement
for _, entry in ipairs(require("integrations.toolchain").requirements("mason")) do
  if entry.name == "vue-language-server" then
    requirement = vim.deepcopy(entry)
  end
end
assert(requirement and requirement.post_install_async)
-- Test the managed fixture regardless of a system Vue server on the host.
requirement.executable = nil
local tc = require("toolchain")
tc.setup({ requirements = { requirement }, notify = false, log_file = temp .. "/events.jsonl" })
vim.fn.writefile({ "9" }, status_file)
tc.install()
assert(tc.wait(5000))
local task = tc.status()[1]
assert(task.state == "failed", vim.inspect(task))
assert(task.message:find("exit 9", 1, true), task.message)
assert(table.concat(task.logs, "\n"):find("fixture npm stderr", 1, true))
vim.fn.writefile({ "0" }, status_file)
tc.retry()
assert(tc.wait(5000))
task = tc.status()[1]
assert(task.state == "skipped" and task.attempt == 2, vim.inspect(task))
assert(installs == 1, "Retry must repair the existing package without reinstalling it")
assert(table.concat(task.logs, "\n"):find("fixture npm output", 1, true))
print("Toolchain actual Mason and Vue repair subprocess: failure, output, retry and installed-package reuse passed")
