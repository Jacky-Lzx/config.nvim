local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.runtimepath:prepend(root)
local before = #vim.api.nvim_get_autocmds({})
require("features.column_guide")
assert(#vim.api.nvim_get_autocmds({}) == before, "Requiring the guide must be pure")
assert(vim.api.nvim_get_namespaces().ConfigColumnGuide == nil)

-- Attach a real UI to an embedded Neovim and inspect its rendered screen cells.
-- Pipes use raw MessagePack so this needs no Python or third-party test library.
local uv = vim.uv
local input, output, errors = uv.new_pipe(false), uv.new_pipe(false), uv.new_pipe(false)
local replies, sequence, stderr = {}, 0, ""
local decoder = vim.mpack.Unpacker()
local exited = false
local startup = vim.env.NVIM_COLUMN_GUIDE_STARTUP == "1"
local args = { "--embed", "--headless", "-u", startup and root .. "/init.lua" or "NONE", "-i", "NONE", "-n" }
if startup then
  vim.list_extend(args, { "--cmd", "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')" })
  args[#args + 1] = assert(vim.env.NVIM_TEST_TMP) .. "/column-guide.txt"
end
local process = assert(uv.spawn("nvim", {
  args = args,
  stdio = { input, output, errors },
}, function()
  exited = true
end))
output:read_start(function(err, data)
  assert(not err, err)
  if not data then
    return
  end
  local offset = 1
  while offset <= #data do
    local message
    message, offset = decoder(data, offset)
    if message and message[1] == 1 then
      replies[message[2]] = message
    end
  end
end)
errors:read_start(function(_, data)
  if data then
    stderr = stderr .. data
  end
end)

local function request(method, ...)
  sequence = sequence + 1
  local id = sequence
  input:write(vim.mpack.encode({ 0, id, method, { ... } }))
  assert(
    vim.wait(3000, function()
      return replies[id] ~= nil or exited
    end),
    "RPC timeout: " .. method .. stderr
  )
  local response = assert(replies[id], "Embedded Neovim exited: " .. stderr)
  assert(response[3] == vim.NIL, vim.inspect(response[3]))
  return response[4]
end

local function run(code)
  return request("nvim_exec_lua", code, {})
end

local function cell(row, col, win)
  return run(([[
    vim.cmd('redraw!')
    local win = %s
    local info = vim.fn.getwininfo(win)[1]
    return vim.fn.screenstring(%d + info.winrow + info.winbar - 1, %d + info.wincol + info.textoff - 1)
  ]]):format(win and tostring(win) or "_G.left or vim.api.nvim_get_current_win()", row, col))
end

local function check()
  request("nvim_ui_attach", 140, 30, { rgb = true, ext_linegrid = true })
  if startup then
    assert(
      run([=[return require('lazy.core.config').plugins['virt-column.nvim'] == nil]=]),
      "Column plugin still configured"
    )
  end
  local initial_errmsg = run([=[return vim.v.errmsg]=])
  run([=[
    vim.opt.rtp:prepend(vim.env.NVIM_CONFIG_ROOT)
    vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(true, false))
    vim.o.number = false
    vim.o.signcolumn = 'no'
    vim.o.wrap = false
    vim.o.tabstop = 8
    vim.o.sidescrolloff = 0
    vim.o.scrolloff = 0
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      'hello', string.rep('a', 120), string.rep('b', 121),
      '\t' .. string.rep('a', 112), '\t' .. string.rep('a', 113),
      string.rep('界', 60), string.rep('界', 61), string.rep('x', 300),
    })
    require('features.column_guide').setup()
  ]=])
  for _, row in ipairs({ 1, 2, 4, 6 }) do
    assert(cell(row, 121) == "", "Missing guide on row " .. row)
  end
  assert(cell(3, 121) == "b" and cell(5, 121) == "a", "Guide overwrote text")
  assert(cell(7, 121) == "界", "Guide overwrote a wide character")
  assert(cell(9, 121) ~= "", "Guide extends beyond buffer lines")
  assert(
    run([=[return #vim.api.nvim_buf_get_extmarks(0, vim.api.nvim_get_namespaces().ConfigColumnGuide, 0, -1, {})]=]) == 0,
    "Guide left persistent extmarks"
  )

  run([=[vim.fn.winrestview({leftcol=20, lnum=8, col=100})]=])
  assert(cell(1, 101) == "", "Horizontal scroll did not move the guide")
  run([=[vim.fn.winrestview({leftcol=130, lnum=8, col=200})]=])
  assert(cell(1, 1) ~= "" and cell(1, 101) ~= "", "Scrolled-out guide stayed visible")
  run([=[vim.fn.winrestview({leftcol=0, lnum=1, col=0}); vim.o.number=true; vim.o.signcolumn='yes:1']=])
  local offset = run([=[return vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].textoff]=])
  assert(offset > 0 and cell(1, 121) == "", "Gutters shifted the guide")
  run([=[vim.o.number=false; vim.o.signcolumn='no']=])
  request("nvim_ui_try_resize", 90, 30)
  assert(cell(1, 89) ~= "", "Guide should be hidden in narrow windows")
  run([=[vim.o.wrap=true]=])
  assert(cell(1, 89) ~= "", "Wrapping drew an off-screen guide")
  request("nvim_ui_try_resize", 300, 30)
  run([=[
    vim.o.wrap=false
    vim.fn.winrestview({leftcol=0, lnum=1, col=0})
    _G.left = vim.api.nvim_get_current_win()
    vim.cmd('vsplit')
    _G.right = vim.api.nvim_get_current_win()
    vim.fn.winrestview({leftcol=20, lnum=8, col=100})
  ]=])
  local right = run([=[vim.cmd('redraw!'); return vim.fn.getwininfo(_G.right)[1]]=])
  assert(cell(1, 121) == "", "Left window lost its guide")
  assert(cell(1, 101, right.winid) == "", "Same-buffer windows share guide position")

  run([=[vim.cmd('enew'); vim.bo.buftype='nofile'; vim.api.nvim_buf_set_lines(0,0,-1,false,{'picker'})]=])
  assert(cell(1, 121, right.winid) ~= "", "Special buffer displayed a guide")
  run([=[
    vim.api.nvim_win_close(_G.right, true)
    vim.api.nvim_set_current_win(_G.left)
    vim.fn.winrestview({leftcol=0, lnum=1, col=0})
    vim.wo.foldmethod='manual'
    vim.cmd('1,3fold')
  ]=])
  assert(cell(1, 121) == "" and cell(2, 121) == "", "Folded lines disrupted the guide")
  run([=[vim.cmd('normal! zR'); vim.bo.filetype='help']=])
  assert(cell(1, 121) ~= "", "Excluded filetype displayed a guide")
  run([=[
    vim.bo.filetype=''
    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_lines(buf,0,-1,false,{'float'})
    _G.float = vim.api.nvim_open_win(buf,false,{relative='editor',row=2,col=0,width=135,height=2})
  ]=])
  assert(
    run([=[vim.cmd('redraw!'); return vim.fn.screenstring(3,121)]=]) ~= "",
    "Normal buffer in floating window displayed a guide"
  )
  run([=[
    vim.api.nvim_win_close(_G.float,true)
    vim.cmd('colorscheme default')
    require('features.column_guide').setup()
  ]=])
  assert(cell(1, 121) == "", "Theme/repeated setup lost the guide")
  run([=[require('features.column_guide').setup({column=25,char='|'})]=])
  assert(cell(1, 25) == "|" and cell(1, 121) ~= "", "Guide configuration did not update")
  assert(run([=[return vim.v.errmsg]=]) == initial_errmsg, "Column guide introduced a redraw error")
end

local ok, err = xpcall(check, debug.traceback)
if not exited then
  input:write(vim.mpack.encode({ 2, "nvim_command", { "qa!" } }))
  if not vim.wait(1000, function()
    return exited
  end) then
    process:kill("sigterm")
  end
end
for _, handle in ipairs({ process, input, output, errors }) do
  if not handle:is_closing() then
    handle:close()
  end
end
assert(ok, err)
print(
  "Native column guide screen, scrolling, windows, folds, Unicode and lifecycle checks passed"
    .. (startup and " (real startup)" or "")
)
