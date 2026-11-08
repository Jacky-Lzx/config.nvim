vim.opt.rtp:prepend(assert(vim.env.NVIM_CONFIG_ROOT))
assert(require("plugins.tasks.task-tools")[1].opts.forward_osc133 == true)
local calls = {}
local manual = {}
for _, name in ipairs({ "prompt", "rerun", "stop", "output", "quickfix" }) do
  manual[name] = function(opts)
    calls[#calls + 1] = { name, opts }
  end
end
package.loaded.task_tools = {
  manual = manual,
  run_file = function()
    calls[#calls + 1] = { "run_file" }
  end,
}
local tasks = require("features.tasks")
assert(#tasks.definitions({ filetype = "python", file = "/file.py" }) == 0)
tasks.prompt()
assert(calls[1][1] == "prompt" and calls[1][2].default == "make")
for _, name in ipairs({ "rerun", "stop", "output", "quickfix", "run_file" }) do
  tasks[name]()
  assert(calls[#calls][1] == name)
end
print("Task configuration delegates workflows while retaining personal defaults")
