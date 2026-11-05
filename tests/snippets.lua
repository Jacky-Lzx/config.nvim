-- Run with the real init.lua in a separate attached UI; no copied plugin trees.
local root = assert(vim.env.NVIM_CONFIG_ROOT)
local stderr = {}
local child = vim.fn.jobstart({
  vim.v.progpath,
  "--embed",
  "-i",
  "NONE",
  "--cmd",
  "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')",
  "-u",
  root .. "/init.lua",
}, {
  rpc = true,
  on_stderr = function(_, data)
    vim.list_extend(stderr, data)
  end,
})
assert(child > 0)
local function rpc(method, ...)
  return vim.rpcrequest(child, method, ...)
end
local function lua(code, ...)
  return rpc("nvim_exec_lua", code, { ... })
end
local function input(keys)
  vim.rpcnotify(child, "nvim_input", keys)
end
local function wait(code, label)
  local done = vim.wait(5000, function()
    return lua(code) == true
  end, 10)
  if not done then
    local state = lua([[local labels={};if package.loaded.completion_tools then
      for _,item in ipairs(require('completion_tools').get_items())do labels[#labels+1]=item.label end end
      return {lines=vim.api.nvim_buf_get_lines(0,0,-1,false),mode=vim.api.nvim_get_mode().mode,
        state=package.loaded.snippet_tools and require('snippet_tools').inspect(),engine=require('integrations.snippets').engine(),
        err=vim.v.errmsg,errors=config_test_errors,menu=labels}]])
    error((label or code) .. "\n" .. vim.inspect(state))
  end
end
local function eq(expected, actual)
  assert(vim.deep_equal(expected, actual), vim.inspect({ expected = expected, actual = actual }))
end
local count = 0
local function test(name, run, filetype)
  if count > 0 then
    input("<Esc><Esc>")
  end
  wait("return vim.api.nvim_get_mode().mode=='n'")
  lua([[
    require('snippet_tools').stop()
    vim.cmd('enew!');vim.bo.filetype='markdown'
    vim.b.completion_tools_sources={'snippets'}
    vim.bo.expandtab=true;vim.bo.shiftwidth=2;vim.bo.autoindent=false;vim.bo.indentexpr=''
    require('integrations.snippets').switch('auto')
  ]])
  if filetype then
    lua([[vim.bo.filetype=...]], filetype)
  end
  local ok, err = xpcall(run, debug.traceback)
  assert(ok, name .. ": " .. tostring(err))
  eq({}, lua("return config_test_errors"))
  count = count + 1
  print("configured snippets: " .. name)
end
local function expand(trigger, key)
  input("i" .. trigger)
  wait(
    "local c=require('completion_tools');return c._can('accept') and c.get_selected_item().label=="
      .. vim.inspect(trigger)
  )
  input(key or "<Tab>")
end
local ok, err = xpcall(function()
  rpc("nvim_ui_attach", 120, 36, { rgb = true })
  lua([[require('lazy').load({plugins={'snippet-tools.nvim','completion-tools.nvim'}})]])
  test("default Markdown route, inherited TeX/global definitions and duplicate filtering", function()
    eq("snippet-tools", lua("return require('integrations.snippets').engine()"))
    lua([[
      assert(require('lazy.core.config').plugins['snippet-tools.nvim']._.loaded)
      local ctx=require('snippet_tools').context();ctx.start_col=0;ctx.mode='insert'
      require('integrations.snippets').source().complete(ctx,function(result)
        local labels,own={},0
        for _,item in ipairs(result.items)do
          if item._snippet_tools then own=own+1 end
          labels[item.label]=(labels[item.label] or 0)+1
        end
        assert(own>=12 and labels.bold==1 and labels.emph==1 and labels.todo==1)
        assert(labels.date and labels['^^'],'inherited snippets missing')
      end)
      assert(not package.loaded.luasnip, 'Default completion loaded LuaSnip')
    ]])
  end)
  test("all Markdown definition names and aliases migrate", function()
    lua([[
      local entries=require('snippet_tools.registry').available(require('snippet_tools').context())
      local labels={};for _,e in ipairs(entries)do labels[e.trigger]=true end
      for _,name in ipairs({'figure','link','code','bold','italic','strike','quote','emph','comment','todo','hide','detail'})do
        assert(labels[name],name)
      end
    ]])
  end)
  test("Tab acceptance and dedicated next/previous field keys", function()
    expand("bold")
    input("text<A-l>!")
    wait("return vim.api.nvim_get_current_line()=='**text**!'")
  end)
  test("Enter confirms new snippets and leaves final cursor after delimiters", function()
    expand("link", "<CR>")
    input("Name<A-l>https://example.com<A-l>!")
    wait("return vim.api.nvim_get_current_line()=='[Name](https://example.com)!'")
  end)
  test("figure filename updates editable alternative text", function()
    expand("figure")
    input("my_figure.png<A-l>")
    wait(
      "return vim.api.nvim_get_current_line()=='![my figure](./Figures_markdown/my_figure.png)' and vim.api.nvim_get_mode().mode=='s'"
    )
    input("Caption<A-l>!")
    wait("return vim.api.nvim_get_current_line()=='![Caption](./Figures_markdown/my_figure.png)!'")
  end)
  test("heading autosnippet processes a burst once", function()
    input("i#3 Title")
    wait("return vim.api.nvim_get_current_line()=='### Title'")
  end)
  test("table generation preserves the existing numbered-cell layout", function()
    input("itable2x2 ")
    wait("return vim.api.nvim_get_mode().mode=='s'")
    eq({ "| 1 | 2 |", "| - | - |", "| 3 | 4 |", "" }, lua("return vim.api.nvim_buf_get_lines(0,0,-1,false)"))
    input("A<A-l>B<A-l>C<A-l>D<A-l>!")
    wait("return vim.api.nvim_get_current_line()=='!'")
    eq({ "| A | B |", "| - | - |", "| C | D |", "!" }, lua("return vim.api.nvim_buf_get_lines(0,0,-1,false)"))
  end)
  test("unordered list generation", function()
    input("iitem3 ")
    wait("return vim.api.nvim_get_mode().mode=='s'")
    eq({ "- 1", "- 2", "- 3" }, lua("return vim.api.nvim_buf_get_lines(0,0,-1,false)"))
  end)
  test("numbered list generation", function()
    input("ienum3 ")
    wait("return vim.api.nvim_get_mode().mode=='s'")
    eq({ "1. 1", "2. 2", "3. 3" }, lua("return vim.api.nvim_buf_get_lines(0,0,-1,false)"))
  end)
  test("inline math auto-expands without a duplicate LuaSnip expansion", function()
    input("imkx<A-l>!")
    wait("return vim.api.nvim_get_current_line()=='$x$!'")
    eq(false, lua("return package.loaded.luasnip~=nil and require('luasnip').locally_jumpable(1)"))
  end)
  test("display math layout", function()
    input("idmx<A-l>!")
    wait("return vim.api.nvim_get_current_line()=='$$!'")
    eq({ "$$", "  x", "$$!" }, lua("return vim.api.nvim_buf_get_lines(0,0,-1,false)"))
  end)
  test("math auto-expansion is suppressed inside existing inline math", function()
    lua([[vim.api.nvim_buf_set_lines(0,0,-1,false,{'$x $'});vim.api.nvim_win_set_cursor(0,{1,3})]])
    input("imk")
    wait("return vim.api.nvim_get_current_line()=='$x mk$'")
    eq(false, lua("return require('snippet_tools').active()"))
  end)
  test("visual selection wraps through backtick without losing text", function()
    lua([[vim.api.nvim_buf_set_lines(0,0,-1,false,{'中文 text'})]])
    input("v$`bold")
    wait("local c=require('completion_tools');return c._can('accept') and c.get_selected_item().label=='bold'")
    input("<Tab>!")
    wait("return vim.api.nvim_get_current_line()=='**中文 text**!'")
  end)
  test("choice cycle and reverse keys follow new engine", function()
    expand("todo")
    input("<A-j>")
    wait("return vim.api.nvim_get_current_line()=='- [x]'")
    input("<A-k>")
    wait("return vim.api.nvim_get_current_line()=='- [ ]'")
  end)
  test("choice picker uses the configured selection UI", function()
    expand("todo")
    input("<A-c>")
    wait("return vim.bo.buftype=='nofile'", "choice UI")
    input("<C-n><CR>")
    wait("return vim.api.nvim_get_current_line()=='- [x]' and require('snippet_tools').active()")
  end)
  test("global date renders without loading LuaSnip", function()
    expand("date")
    input("!")
    wait("return vim.api.nvim_get_current_line()==os.date('%Y.%m.%d')..'!'")
    eq(false, lua("return package.loaded.luasnip~=nil"))
  end, "lua")
  test("Lua require derives an editable local name", function()
    expand("req")
    input("pkg.module<A-l>")
    wait(
      [[return vim.api.nvim_get_current_line()=='local module = require("pkg.module")' and vim.api.nvim_get_mode().mode=='s']]
    )
    input("Alias<A-l>!")
    wait([[return vim.api.nvim_get_current_line()=='local Alias = require("pkg.module")!']])
  end, "lua")
  test("Python imports retain named fields and reverse jumps", function()
    expand("fras")
    input("pathlib<A-l>Path<A-l>P<A-h>PurePath<A-l><A-l>!")
    wait([[return vim.api.nvim_get_current_line()=='from pathlib import PurePath as P!']])
  end, "python")
  test("Rust snippet uses native completion", function()
    expand("hello")
    input("!")
    wait([[return vim.api.nvim_get_current_line()=='println!("Hello world");!']])
  end, "rust")
  test("Typst figure label follows filename changes", function()
    expand("figure")
    input("my_plot.png<A-l>Caption<A-l>!")
    wait(
      [[return vim.api.nvim_get_current_line()=='#figure(image("./Figures/my_plot.png", width: 80%), caption: [Caption]) <fig:my_plot>!']]
    )
  end, "typst")
  test("SystemVerilog inherits native loops and live mirrors", function()
    expand("for")
    input("index<A-l>10<A-l>body<A-l>!")
    wait(
      [[return table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),'\n')=='for (index= 0; index < 10; index = index + 1) begin\n  body!\nend']]
    )
    eq(false, lua("return package.loaded.luasnip~=nil"))
  end, "systemverilog")
  test("native TODO aliases and signature choice", function()
    lua([[vim.bo.commentstring='-- %s']])
    expand("fix")
    input("<A-j>")
    wait([[return vim.api.nvim_get_current_line():find('-- BUG:',1,true)~=nil]])
    input("<A-l><A-l><A-j>")
    wait([[return not vim.api.nvim_get_current_line():find('lzx',1,true)]])
    eq(false, lua("return package.loaded.luasnip~=nil"))
  end, "lua")
  test("buffer-local toggle restores original LuaSnip Markdown definitions", function()
    lua([[vim.cmd('SnippetEngine luasnip')]])
    eq("luasnip", lua("return require('integrations.snippets').engine()"))
    expand("bold")
    input("legacy<A-l>!")
    wait("return vim.api.nvim_get_current_line()=='**legacy**!'")
    eq(false, lua("return require('snippet_tools').active()"))
  end)
  test("LuaSnip automatic Markdown expansion and toggle back", function()
    lua([[vim.cmd('SnippetEngine luasnip')]])
    input("i#3 Title")
    wait("return vim.api.nvim_get_current_line()=='### Title'")
    input("<Esc>")
    wait("return vim.api.nvim_get_mode().mode=='n'")
    lua([[vim.cmd('SnippetEngineToggle')]])
    eq("snippet-tools", lua("return require('integrations.snippets').engine()"))
  end)
  test("switching stops active sessions and remains buffer-local", function()
    expand("bold")
    wait("return require('snippet_tools').active()")
    lua(
      [[vim.cmd('SnippetEngine luasnip');assert(not require('snippet_tools').active());first=vim.api.nvim_get_current_buf();vim.cmd('enew!');vim.bo.filetype='markdown']]
    )
    eq("snippet-tools", lua("return require('integrations.snippets').engine()"))
    lua([[vim.api.nvim_set_current_buf(first)]])
    eq("luasnip", lua("return require('integrations.snippets').engine()"))
  end)
  test("new Lua buffers default to native snippets", function()
    lua([[vim.cmd('enew!');vim.bo.filetype='lua']])
    eq("snippet-tools", lua("return require('integrations.snippets').engine()"))
  end)
end, debug.traceback)
pcall(rpc, "nvim_command", "qa!")
vim.fn.jobstop(child)
assert(ok, tostring(err) .. "\nSTDERR: " .. table.concat(stderr, "\n"))
print("configured snippets: " .. count .. " scenarios passed")
