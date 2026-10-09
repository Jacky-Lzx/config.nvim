local root = vim.fn.getcwd()
vim.opt.runtimepath:prepend(root)

-- Stub discovery rather than depending on installed interpreters or plugins.
local paths = {}
local executables = {}
vim.fn.exepath = function(name)
  return paths[name] or ""
end
vim.fn.executable = function(path)
  return executables[path] and 1 or 0
end
vim.env.VIRTUAL_ENV = nil
vim.env.CONDA_PREFIX = nil
vim.env.NVIM_PYTHON3_HOST_PROG = "/provider/python"
executables["/provider/python"] = true
local platform = require("utils.platform")
local count = 0
local function check(expected)
  assert(platform.python() == expected, vim.inspect({ expected = expected, actual = platform.python() }))
  count = count + 1
end

check("python3")
assert(platform.python_host() == "/provider/python")
paths.python = "/system/python"
check("/system/python")
paths.python3 = "/system/python3"
check("/system/python3")
vim.env.CONDA_PREFIX = "/conda"
executables["/conda/bin/python"] = true
check("/conda/bin/python")
vim.env.VIRTUAL_ENV = "/project/.venv"
executables["/project/.venv/bin/python"] = true
check("/project/.venv/bin/python")
local selected = "/selected env/bin/python"
executables[selected] = true
package.loaded["venv-selector"] = {
  python = function()
    return selected
  end,
}
check(selected)
selected = "/missing/python"
check("/project/.venv/bin/python")
selected = nil
check("/project/.venv/bin/python")
vim.env.VIRTUAL_ENV = "/missing"
check("/conda/bin/python")
vim.env.CONDA_PREFIX = ""
executables["/bin/python"] = true
check("/system/python3")

vim.api.nvim_buf_set_name(0, root .. "/a file's script.py")
vim.bo.filetype = "python"
dofile(root .. "/after/ftplugin/python.lua")
vim.env.NVIM_PYTHON_MAKE = "/stale/interpreter"
local template = dofile(root .. "/lua/overseer/template/user/python.lua")
for _, interpreter in ipairs({ "/selected env/bin/python", "/another' env/bin/python" }) do
  selected = interpreter
  executables[selected] = true
  local file = vim.fn.expand("%:p")
  local params = { args = { "--name", "a b" } }
  local task = template.builder(params)
  assert(vim.deep_equal(task.cmd, { selected }))
  assert(vim.deep_equal(task.args, { file, "--name", "a b" }))
  assert(vim.deep_equal(params.args, { "--name", "a b" }))
  count = count + 1
end
-- Select after ftplugin load, then exercise real shell execution without Python.
vim.o.shell = "/bin/sh"
vim.o.shellpipe = ">%s 2>&1"
vim.bo.errorformat = "%m"
local temp = vim.fn.tempname()
vim.fn.mkdir(temp, "p")
local ok, err = xpcall(function()
  for i, command in ipairs({ "make", "lmake", "make" }) do
    selected = temp .. "/env " .. i .. "'s python"
    vim.fn.writefile({ "#!/bin/sh", "printf '%s\\n' 'environment " .. i .. '\' "$@"' }, selected)
    assert(vim.fn.setfperm(selected, "rwx------") == 1)
    executables[selected] = true
    vim.cmd("silent " .. command .. "!")
    assert(vim.v.shell_error == 0)
    local items = command == "make" and vim.fn.getqflist() or vim.fn.getloclist(0)
    assert(#items == 2, vim.inspect(items))
    assert(items[1].text == "environment " .. i)
    assert(items[2].text == vim.fn.expand("%:p"))
    count = count + 1
  end

  vim.cmd.enew()
  vim.bo.filetype = "lua"
  vim.bo.makeprg = "printf non-python"
  vim.bo.errorformat = "%m"
  local previous = vim.env.NVIM_PYTHON_MAKE
  selected = "/must/not/be/used"
  for _, command in ipairs({ "make", "lmake" }) do
    vim.cmd("silent " .. command .. "!")
    assert(vim.v.shell_error == 0)
    local items = command == "make" and vim.fn.getqflist() or vim.fn.getloclist(0)
    assert(#items == 1 and items[1].text == "non-python", vim.inspect(items))
    assert(vim.bo.makeprg == "printf non-python")
    assert(vim.env.NVIM_PYTHON_MAKE == previous)
    count = count + 1
  end
  vim.bo.filetype = "python"
  vim.cmd("silent make!")
  assert(vim.v.shell_error == 0)
  assert(vim.bo.makeprg == "printf non-python")
  assert(vim.env.NVIM_PYTHON_MAKE == previous, "custom Python makeprg must be left alone")
  count = count + 1
end, debug.traceback)
vim.fn.delete(temp, "rf")
assert(ok, err)
assert(platform.python_host() == "/provider/python")
print("python: " .. count .. " tests passed")
