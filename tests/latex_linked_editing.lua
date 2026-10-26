-- Optional real-UI integration; requires an installed texquill (or NVIM_TEXQUILL).
-- NVIM_CONFIG_ROOT="$PWD" nvim --headless -u NONE -i NONE --noplugin -l tests/latex_linked_editing.lua
local root = assert(vim.env.NVIM_CONFIG_ROOT)
local candidate = vim.env.NVIM_LINKED_EDITING_CANDIDATE
local uv = vim.uv
local input, output, errors = uv.new_pipe(false), uv.new_pipe(false), uv.new_pipe(false)
local replies, sequence, stderr = {}, 0, ""
local decoder = vim.mpack.Unpacker()
local exited = false
local process = assert(uv.spawn("nvim", {
  args = { "--embed", "--headless", "-u", "NONE", "--noplugin", "-i", "NONE", "-n" },
  stdio = { input, output, errors },
}, function()
  exited = true
end))
output:read_start(function(err, data)
  assert(not err, err)
  if data then
    local offset = 1
    while offset <= #data do
      local message
      message, offset = decoder(data, offset)
      if message and message[1] == 1 then
        replies[message[2]] = message
      end
    end
  end
end)
errors:read_start(function(_, data)
  stderr = stderr .. (data or "")
end)
local function request(method, ...)
  sequence = sequence + 1
  local id = sequence
  input:write(vim.mpack.encode({ 0, id, method, { ... } }))
  assert(
    vim.wait(5000, function()
      return replies[id] ~= nil or exited
    end),
    "RPC timeout: " .. method .. stderr
  )
  local response = assert(replies[id], "Embedded Neovim exited: " .. stderr)
  assert(response[3] == vim.NIL, vim.inspect(response[3]))
  return response[4]
end
local function run(code, ...)
  return request("nvim_exec_lua", code, { ... })
end
local function until_value(code, expected, label)
  local deadline = uv.hrtime() + 5e9
  local actual
  repeat
    actual = run(code)
    if vim.deep_equal(actual, expected) then
      return
    end
    vim.wait(20, function()
      return false
    end)
  until uv.hrtime() >= deadline
  error(label .. ": " .. vim.inspect(actual) .. " expected " .. vim.inspect(expected) .. stderr)
end
local function pair(name)
  return "\\begin{quote}A\\begin{" .. name .. "}x\\end{" .. name .. "}B\\end{quote}"
end
local function check_pair(name, label)
  until_value("return vim.api.nvim_buf_get_lines(0, 2, 3, false)[1]", pair(name), label)
end
local function move(name, closing, star)
  run(
    [=[
    local name, closing, star = ...
    local line = vim.api.nvim_buf_get_lines(0, 2, 3, false)[1]
    local prefix = closing and '\\end{' or '\\begin{'
    local first = assert(line:find(prefix .. name, 1, true)) + #prefix - 1
    vim.api.nvim_win_set_cursor(0, { 3, first + (star and #name - 1 or 1) })
  ]=],
    name,
    closing,
    star
  )
  until_value(
    [=[
    local namespaces = vim.api.nvim_get_namespaces()
    local ns = namespaces['latex.linked_editing:' .. _G.client_id .. ':' .. vim.api.nvim_get_current_buf()]
      or namespaces['nvim.lsp.linked_editing_range:' .. _G.client_id]
    return ns and #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {}) or 0
  ]=],
    2,
    "linked ranges did not become ready"
  )
end
local function keys(text)
  request("nvim_input", run("return vim.keycode(...)", text))
end
local function check()
  request("nvim_ui_attach", 120, 30, { rgb = true, ext_linegrid = true })
  run(
    [=[
    local root, candidate = ...
    vim.opt.rtp:prepend(root)
    if candidate then vim.opt.rtp:prepend(candidate) end
    local integration = require('languages.latex.lsp')
    local executable = assert(integration.executable(), 'Install texquill or set NVIM_TEXQUILL')
    local directory = vim.fn.tempname()
    vim.fn.mkdir(directory, 'p')
    local file = directory .. '/main.tex'
    vim.fn.writefile({ '\\documentclass{article}', '\\begin{document}', '\\begin{quote}A\\begin{equation}x\\end{equation}B\\end{quote}', '\\end{document}' }, file)
    vim.cmd.edit(file)
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false
    _G.client_id = assert(vim.lsp.start({ name='texquill', cmd={executable, '--stdio'}, root_dir=directory,
      capabilities=capabilities, init_options={distribution={enabled=false}}, on_attach=integration.attach }))
  ]=],
    root,
    candidate
  )
  until_value("return vim.lsp.get_client_by_id(_G.client_id).initialized", true, "LSP did not initialize")
  move("equation", false)
  keys("ea*")
  check_pair("equation*", "star appended at opener did not mirror")
  keys("<Esc>u")
  check_pair("equation", "undo did not restore both names")
  keys("<C-r>")
  check_pair("equation*", "redo did not restore both names")
  move("equation*", true, true)
  keys("x")
  check_pair("equation", "star removed at closer did not mirror")
  move("equation", true)
  keys("ea*")
  check_pair("equation*", "star appended at closer did not mirror")
  keys("<Esc>")
  move("equation*", false, true)
  keys("x")
  check_pair("equation", "star removed at opener did not mirror")
  move("equation", false)
  keys("ciw")
  check_pair("", "ciw did not retain both empty names")
  keys("align")
  check_pair("align", "ciw insertion did not mirror")
  keys("*")
  check_pair("align*", "star inserted after ciw did not mirror")
  keys("<Esc>")
  move("align*", false, true)
  keys("x")
  check_pair("align", "star deletion broke linked editing")
  move("align", false)
  keys("ciw")
  check_pair("", "second ciw did not retain empty names")
  keys("环境")
  check_pair("环境", "Unicode name did not mirror")
  keys("<Esc>")
  move("环境", false)
  keys("ea\\")
  until_value(
    "return vim.api.nvim_buf_get_lines(0, 2, 3, false)[1]",
    "\\begin{quote}A\\begin{环境\\}x\\end{环境}B\\end{quote}",
    "invalid name escaped its range"
  )
  keys("<Esc>")
  run("vim.lsp.get_client_by_id(_G.client_id):stop(true)")
  until_value(
    [=[
    for _, item in ipairs(vim.api.nvim_get_autocmds({})) do
      if item.group_name and item.group_name:match('^LatexLinkedEditing') then return false end
    end
    return true
  ]=],
    true,
    "linked editing autocmds survived client detach"
  )
  assert(run("return vim.v.errmsg") == "", run("return vim.v.errmsg"))
end
local ok, err = xpcall(check, debug.traceback)
pcall(request, "nvim_command", "qa!")
if not vim.wait(3000, function()
  return exited
end) then
  process:kill("sigkill")
end
input:close()
output:close()
errors:close()
process:close()
assert(ok, err)
print("LaTeX linked editing: real UI star insertion/deletion, ciw, Unicode, nested scope, undo/redo and detach passed")
