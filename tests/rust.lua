vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.opt.runtimepath:prepend(vim.fn.stdpath("data") .. "/lazy/nvim-dap")
local dap = require("dap")
local abort = dap.ABORT
local program = require("languages.rust.plugins")[2].opts.configurations.rust[1].program
local notices, callback, selection, result, resumed
vim.notify = function(message)
  notices[#notices + 1] = message
end
vim.ui.select = function(items, _, cb)
  selection = { items = items, callback = cb }
end
local function start(spawn_error)
  notices, callback, selection, result, resumed = {}, nil, nil, nil, false
  vim.system = function(argv, opts, cb)
    assert(vim.deep_equal(argv, { "cargo", "build", "--message-format=json" }))
    assert(opts.cwd == vim.fn.getcwd() and opts.text)
    if spawn_error then
      error("cargo not found")
    end
    callback = cb
    return {}
  end
  -- Exercise the installed DAP evaluator without starting a debug adapter.
  local co = coroutine.create(function()
    result = dap.listeners.on_config["dap.expand_variable"]({ program = program }).program
    resumed = true
  end)
  assert(coroutine.resume(co))
  assert(vim.wait(1000, function()
    return callback ~= nil or resumed
  end))
  if not spawn_error then
    assert(not resumed, "build must not block or finish before process completion")
  end
end
local function complete(stdout, code, stderr)
  callback({ stdout = stdout, code = code or 0, stderr = stderr or "" })
  assert(vim.wait(1000, function()
    return resumed or selection ~= nil
  end))
end
local function artifact(path)
  return vim.json.encode({ reason = "compiler-artifact", executable = path }) .. "\n"
end
start()
complete(
  artifact(vim.NIL) .. artifact("/custom target/debug/real-bin.exe") .. artifact("/custom target/debug/real-bin.exe")
)
assert(result == "/custom target/debug/real-bin.exe" and #notices == 0)
start()
complete(artifact("/target/a") .. artifact("/target/b"))
assert(not resumed and vim.deep_equal(selection.items, { "/target/a", "/target/b" }))
selection.callback(selection.items[2])
assert(resumed and result == "/target/b")
start()
complete(artifact("/target/a") .. artifact("/target/b"))
selection.callback(nil)
assert(resumed and result == abort and #notices == 0)
start()
complete(artifact("/stale"), 101, "compile error")
assert(result == abort and notices[1]:find("compile error", 1, true))
start()
complete(artifact(vim.NIL))
assert(result == abort and notices[1]:find("no executable", 1, true))
for _, invalid in ipairs({ "not json", "null", "42" }) do
  start()
  complete(invalid)
  assert(result == abort and notices[1]:find("invalid JSON", 1, true))
end
start(true)
assert(result == abort and notices[1]:find("cargo not found", 1, true))
print("rust: 9 tests passed")
