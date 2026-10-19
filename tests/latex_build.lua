-- Optional live integration: nvim --clean --headless -i NONE -l tests/latex_build.lua
local root = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(debug.getinfo(1, "S").source:sub(2))))
vim.opt.runtimepath:prepend(root)
vim.o.swapfile, vim.o.shadafile = false, "NONE"
local directory = vim.fn.tempname() .. " latex build"
vim.fn.mkdir(directory, "p")
local client
local function check()
  assert(vim.fn.executable("latexmk") == 1, "Install latexmk and a TeX distribution")
  local source = directory .. "/main.tex"
  local text = { [[\documentclass{article}]], [[\begin{document}]], "First version.", [[\end{document}]] }
  vim.fn.writefile(text, source)
  vim.fn.writefile({}, directory .. "/.latexmkrc")
  vim.lsp.enable("latex_lsp")
  vim.cmd.edit(vim.fn.fnameescape(source))
  assert(
    vim.wait(10000, function()
      client = vim.lsp.get_clients({ bufnr = 0, name = "latex_lsp" })[1]
      return client and client.initialized
    end, 20),
    "latex-lsp did not attach automatically"
  )
  assert(client.root_dir == directory)
  assert(#vim.lsp.get_clients({ name = "texlab" }) == 0)
  assert(client.server_capabilities.diagnosticProvider, "Pull diagnostics not negotiated")
  local bufnr = vim.api.nvim_get_current_buf()
  local builds, finished, refreshes = 0, nil, 0
  local started = client.handlers["latex/buildStarted"]
  local completed = client.handlers["latex/buildFinished"]
  local refresh = client.handlers["workspace/diagnostic/refresh"]
  client.handlers["latex/buildStarted"] = function(...)
    builds = builds + 1
    return started(...)
  end
  client.handlers["latex/buildFinished"] = function(err, result, ...)
    finished = result
    return completed(err, result, ...)
  end
  client.handlers["workspace/diagnostic/refresh"] = function(...)
    refreshes = refreshes + 1
    return refresh(...)
  end
  local function wait_build(status)
    assert(
      vim.wait(30000, function()
        return finished ~= nil
      end, 20),
      "Build did not finish"
    )
    assert(finished.status == status and not finished.stale, vim.inspect(finished))
  end
  local function save(line, status)
    finished = nil
    vim.api.nvim_buf_set_lines(bufnr, 2, 3, false, { line })
    vim.cmd.write()
    wait_build(status)
  end
  save("Built on save.", "success")
  assert(vim.fn.filereadable(directory .. "/build/latex-lsp/main.pdf") == 1)
  assert(vim.fn.filereadable(directory .. "/build/latex-lsp/main.synctex.gz") == 1)
  assert(builds == 1, "Save queued duplicate builds")
  -- Invoke the actual local shortcut with unsaved contents: didSave owns this build.
  local previous = builds
  finished = nil
  vim.api.nvim_buf_set_lines(bufnr, 2, 3, false, { "Built with the manual shortcut." })
  vim.fn.maparg("<leader>lb", "n", false, true).callback()
  wait_build("success")
  vim.wait(300, function()
    return false
  end, 20)
  assert(builds == previous + 1, "Manual shortcut queued duplicate builds")
  save([[$\epsilonn$]], "error")
  assert(
    vim.wait(5000, function()
      return vim.iter(vim.diagnostic.get(bufnr)):any(function(d)
        return d.code == "undefined-control-sequence" and d.lnum == 2 and d.col == 1
      end)
    end, 20),
    "Compiler diagnostics did not refresh: " .. vim.inspect(vim.diagnostic.get(bufnr))
  )
  save([[$\epsilon$]], "success")
  assert(
    vim.wait(5000, function()
      return #vim.diagnostic.get(bufnr) == 0
    end, 20),
    "Corrected diagnostics were not cleared"
  )
  assert(refreshes > 0, "No native diagnostic refresh")
  -- The same native server must attach to BibTeX files as well.
  vim.fn.writefile({ "@article{example, title={Example}}" }, directory .. "/refs.bib")
  vim.cmd.edit(vim.fn.fnameescape(directory .. "/refs.bib"))
  assert(
    vim.wait(5000, function()
      return vim.lsp.buf_is_attached(0, client.id)
    end, 20),
    "latex-lsp did not attach to BibTeX"
  )
  print(
    "Live latex-lsp passed: automatic TeX/BibTeX attachment, save/manual builds, PDF/SyncTeX and diagnostic refresh/clearing"
  )
end
local ok, err = xpcall(check, debug.traceback)
if client then
  client:stop(true)
  vim.wait(5000, function()
    return client:is_stopped()
  end, 20)
end
vim.fn.delete(directory, "rf")
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
end
vim.cmd("qa!")
