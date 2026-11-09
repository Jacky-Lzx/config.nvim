-- Run with the real init.lua in a separate attached UI; no copied plugin trees.
local root = assert(vim.env.NVIM_CONFIG_ROOT)
local stderr = {}
local child = vim.fn.jobstart({
  vim.v.progpath,
  "--embed",
  "-i",
  "NONE",
  "--cmd",
  "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/support/setup.lua')",
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
local function test(name, run)
  if count > 0 then
    input("<Esc><Esc>")
  end
  wait("return vim.api.nvim_get_mode().mode=='n'")
  lua([[
    require('snippet_tools').stop()
    vim.cmd('enew!');vim.bo.filetype='tex'
    vim.b.completion_tools_sources={'snippets'}
    vim.bo.expandtab=true;vim.bo.shiftwidth=2;vim.bo.autoindent=false;vim.bo.indentexpr=''
  ]])
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
local function buffer(lines, row, col)
  lua(
    [[local lines,row,col=...;vim.api.nvim_buf_set_lines(0,0,-1,false,lines);vim.api.nvim_win_set_cursor(0,{row,col})]],
    lines,
    row or 1,
    col or 0
  )
end
local function wait_line(text)
  wait("return vim.api.nvim_get_current_line()==" .. vim.inspect(text))
end
local function math_buffer()
  buffer({ "$ $" }, 1, 1)
end
local function lines()
  return lua("return vim.api.nvim_buf_get_lines(0,0,-1,false)")
end
local ok, err = xpcall(function()
  rpc("nvim_ui_attach", 120, 36, { rgb = true })
  lua(
    [[for _, id in ipairs({'snippet-tools.nvim','completion-tools.nvim'}) do require("plugin_tools").activate(id); if id=='snippet-tools.nvim' then require('snippet_tools.bootstrap').ensure() elseif id=='completion-tools.nvim' then require('completion_tools.bootstrap').ensure() end end]]
  )
  test("TeX and global snippets use only the native engine", function()
    eq("snippet-tools", lua("return require('integrations.snippets').engine()"))
    lua([[local ctx=require('snippet_tools').context();ctx.start_col=0;ctx.mode='insert'
      require('integrations.snippets').source().complete(ctx,function(result)
        local labels={};for _,item in ipairs(result.items)do
          labels[item.label]=(labels[item.label] or 0)+1
          if item.label=='bf' then assert(item._snippet_tools,'legacy TeX duplicate') end
        end
        assert(labels.bf==1 and labels.begin==1 and labels.date==1)
      end)
      assert(not package.loaded.luasnip, 'Default TeX completion loaded LuaSnip')]])
  end)
  test("begin/end mirrors environment names and enters the body", function()
    expand("begin")
    input("example<A-l>body")
    wait_line("  body")
    eq({ "\\begin{example}", "  body", "\\end{example}" }, lines())
  end)
  test("native node decorations match configured insert and choice indicators", function()
    expand("figure")
    wait("return vim.api.nvim_get_mode().mode=='s'")
    lua([[
      function native_decoration(icon, group)
        local ns=vim.api.nvim_get_namespaces()['snippet-tools']
        for _,mark in ipairs(vim.api.nvim_buf_get_extmarks(0,ns,0,-1,{details=true})) do
          local d=mark[4]
          local eol_ns=vim.api.nvim_get_namespaces()['snippet-tools.eol']
          local eol=vim.api.nvim_buf_get_extmark_by_id(0,eol_ns,mark[1],{details=true})
          local text=d.virt_text or (#eol>0 and eol[3].virt_text)
          if d.priority==130 and text then
            return text[1][1]==icon and text[1][2]==group
              and d.sign_text:match('%S+')==icon and d.sign_hl_group==group
          end
        end
        return false
      end
      assert(native_decoration('','Type'))
    ]])
    input("<A-l>")
    wait("return vim.api.nvim_get_mode().mode=='s' and native_decoration('','Identifier')")
    lua([[
      local ns=vim.api.nvim_get_namespaces()['snippet-tools']
      local passive=false
      for _,mark in ipairs(vim.api.nvim_buf_get_extmarks(0,ns,0,-1,{details=true})) do
        local d=mark[4]
        local eol_ns=vim.api.nvim_get_namespaces()['snippet-tools.eol']
        local eol=vim.api.nvim_buf_get_extmark_by_id(0,eol_ns,mark[1],{details=true})
        local text=d.virt_text or (#eol>0 and eol[3].virt_text)
        if text and text[1][1]=='' then
          passive=text[1][2]=='Comment' and d.sign_hl_group=='Comment'
        end
      end
      assert(passive)
      require('snippet_tools').stop()
      assert(#vim.api.nvim_buf_get_extmarks(0,ns,0,-1,{})==0)
      assert(#vim.api.nvim_buf_get_extmarks(0,vim.api.nvim_get_namespaces()['snippet-tools.eol'],0,-1,{})==0)
    ]])
  end)
  test("final stop uses a separate flag and disappears on exit", function()
    expand("bf")
    wait("return vim.api.nvim_get_mode().mode=='i'")
    lua([[
      local ns=vim.api.nvim_get_namespaces()['snippet-tools']
      local eol_ns=vim.api.nvim_get_namespaces()['snippet-tools.eol']
      local flag=false
      for _,mark in ipairs(vim.api.nvim_buf_get_extmarks(0,ns,0,-1,{details=true})) do
        local d=mark[4]
        if d.sign_text and d.sign_text:match('%S+')=='' then
          local text=vim.api.nvim_buf_get_extmark_by_id(0,eol_ns,mark[1],{details=true})[3].virt_text[1]
          assert(text[1]=='' and text[2]=='Comment' and d.sign_hl_group=='Comment')
          flag=true
        end
      end
      assert(flag)
    ]])
    input("text<A-l>!")
    wait_line("\\textbf{text}!")
    lua([[
      local ns=vim.api.nvim_get_namespaces()['snippet-tools.eol']
      assert(#vim.api.nvim_buf_get_extmarks(0,ns,0,-1,{})==0)
    ]])
  end)
  test("visual TeX wrapper preserves Unicode", function()
    buffer({ "中文 text" })
    input("v$`bf")
    wait("local c=require('completion_tools');return c._can('accept') and c.get_selected_item().label=='bf'")
    input("<Tab>!")
    wait_line("\\textbf{中文 text}!")
  end)
  test("inline math uses TeX delimiters once", function()
    input("imkx<A-l>!")
    wait_line("\\( x \\)!")
    eq(false, lua("return package.loaded.luasnip~=nil"))
  end)
  test("display math retains indentation", function()
    input("idmx<A-l>!")
    wait_line("\\]!")
    eq({ "\\[", "  x", "\\]!" }, lines())
  end)
  test("math trigger is suppressed inside existing math", function()
    math_buffer()
    input("imk")
    wait_line("$mk $")
  end)
  test("fraction fields and final cursor", function()
    math_buffer()
    input("i//x<A-l>y<A-l>!")
    wait_line("$\\frac{x}{y}! $")
  end)
  for _, spec in ipairs({
    { "vec", "\\vec{x}" },
    { "hat", "\\hat{x}" },
    { "bar", "\\overline{x}" },
    { "overline", "\\overline{x}" },
    { "rm", "\\mathrm{x}" },
    { "sr", "x^2" },
    { "cb", "x^3" },
    { "sq", "\\sqrt{x}" },
  }) do
    test("postfix " .. spec[1], function()
      math_buffer()
      input("ix" .. spec[1])
      wait("return vim.api.nvim_get_current_line()==" .. vim.inspect("$" .. spec[2] .. " $"))
    end)
  end
  test("postfix fraction capture fills numerator", function()
    math_buffer()
    input("ix//y<A-l>!")
    wait_line("$\\frac{x}{y}! $")
  end)
  test("postfix does not fire outside math", function()
    input("ixvec")
    wait_line("xvec")
  end)
  test("unconditional scripts preserve word-internal behavior", function()
    input("ix^^2<A-l>+y__i<A-l>!")
    wait_line("x^{2}+y_{i}!")
  end)
  test("equation star choice regenerates labels and preserves edited content", function()
    expand("equation")
    input("<A-l>x<A-h><A-j>")
    wait(
      [[return table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),'\n')=='\\begin{equation*}\n  x\n\\end{equation*}']]
    )
    input("<A-k>")
    wait([[return table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),'\n'):find('\\label{eq:}',1,true)~=nil]])
    assert(table.concat(lines(), "\n"):find("  x", 1, true))
  end)
  test("figure choices and filename label linkage", function()
    expand("figure")
    input("<A-j><A-l>7<A-l>draft.v2/my_figure.pdf<A-l>Caption<A-l>!")
    wait_line("\\end{figure}!")
    local text = table.concat(lines(), "\n")
    assert(text:find("\\begin{figure}[htbp]", 1, true), text)
    assert(text:find("width=0.7\\linewidth", 1, true), text)
    assert(text:find("{./Figures/draft.v2/my_figure.pdf}", 1, true), text)
    assert(text:find("\\label{fig:my-figure}", 1, true), text)
  end)
  test("item and align conditions follow structural environments", function()
    buffer({ "\\begin{itemize}", "  ", "\\end{itemize}" }, 2, 2)
    input("A;t")
    wait_line("  \\item ")
    input("<Esc>")
    wait("return vim.api.nvim_get_mode().mode=='n'")
    buffer({ "\\begin{align}", "  ", "\\end{align}" }, 2, 2)
    input("A==<A-l>x<A-l>")
    wait_line("  &= x \\\\")
  end)
  test("text and math box candidates follow context", function()
    expand("box")
    input("text<A-l>!")
    wait_line("\\fbox{text}!")
    input("<Esc>")
    wait("return vim.api.nvim_get_mode().mode=='n'")
    math_buffer()
    expand("box")
    input("x<A-l>!")
    wait_line("$\\boxed{x}! $")
  end)
  test("subfigure and Beamer candidates are context specific", function()
    lua([[local available=require('snippet_tools').available();local count=0
      for _,entry in ipairs(available)do
        assert(entry.trigger~='frame' and entry.trigger~='columns','Beamer leaked into article')
        if entry.trigger=='subfigure' then count=count+1;assert(entry.description=='Subfigure') end
      end;assert(count==1)]])
    buffer({ "\\begin{figure}", "", "\\end{figure}" }, 2, 0)
    lua([[local count=0;for _,entry in ipairs(require('snippet_tools').available())do
      if entry.trigger=='subfigure' then count=count+1;assert(entry.description=='Subfigure (simple)') end
    end;assert(count==1)]])
  end)
  test("RGB choice keeps all nested editable fields", function()
    expand("color")
    input("<A-j><A-l>10<A-l>20<A-l>30<A-l>Text<A-l>!")
    wait_line("\\textcolor[RGB]{10,20,30}{Text}!")
  end)
  test("Beamer columns keep linked widths", function()
    buffer({ "\\documentclass{beamer}", "\\begin{document}", "", "\\end{document}" }, 3, 0)
    expand("columns")
    input("30<A-l>Left<A-l>Right")
    wait_line("    Right")
    local text = table.concat(lines(), "\n")
    assert(text:find("{0.30\\linewidth}", 1, true), text)
    assert(text:find("{0.68\\linewidth}", 1, true), text)
  end)
  test("Beamer frame has editable title and fragile choice", function()
    buffer({ "\\documentclass{beamer}", "\\begin{document}", "", "\\end{document}" }, 3, 0)
    expand("frame")
    input("<A-l>Intro<A-l><A-j><A-l>Body")
    wait_line("  Body")
    assert(table.concat(lines(), "\n"):find("\\begin{frame}[fragile]{Intro}", 1, true))
  end)
  test("native TeX reload preserves formatting and field navigation", function()
    lua([[vim.cmd('SnippetToolsReload')]])
    expand("bf")
    input("native<A-l>!")
    wait_line("\\textbf{native}!")
    eq(false, lua("return package.loaded.luasnip~=nil"))
  end)
  test("native autosnippets survive repeated reload without double expansion", function()
    lua([[vim.cmd('SnippetToolsReload');vim.cmd('SnippetToolsReload')]])
    input("imkx<A-l>!")
    wait_line("\\( x \\)!")
    lua([[assert(not require('config.plugins').nodes().LuaSnip);assert(vim.fn.exists(':SnippetEngine')==0)]])
  end)
end, debug.traceback)
pcall(rpc, "nvim_command", "qa!")
vim.fn.jobstop(child)
assert(ok, tostring(err) .. "\nSTDERR: " .. table.concat(stderr, "\n"))
print("Configured LaTeX snippets: " .. count .. " scenarios passed")
