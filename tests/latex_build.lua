-- Optional real-toolchain check, separate from offline smoke tests.
-- TMPDIR=/private/tmp nvim --clean --headless -i NONE -l tests/latex_build.lua
local root = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(debug.getinfo(1, "S").source:sub(2))))
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "nvim-lspconfig"))
local plugin = require("utils.platform").dev_plugin_root() .. "/tex-tools.nvim"
assert(vim.uv.fs_stat(plugin), "This live check requires the local tex-tools checkout")
vim.opt.rtp:prepend(plugin)
vim.o.swapfile, vim.o.shadafile = false, "NONE"
local directory = vim.fn.tempname() .. " latex build"
vim.fn.mkdir(directory, "p")
local client
local function check()
  assert(vim.fn.executable("texlab") == 1 and vim.fn.executable("latexmk") == 1, "Install texlab and latexmk")
  local source = directory .. "/main.tex"
  local text = { "\\documentclass{article}", "\\begin{document}", "First version.", "\\end{document}" }
  vim.fn.writefile(text, source)
  vim.fn.writefile({}, directory .. "/.texlabroot")
  vim.fn.writefile({ '$out_dir = "build";' }, directory .. "/.latexmkrc")
  vim.cmd.edit(vim.fn.fnameescape(source))
  vim.bo.filetype = "tex"
  local tex = require("tex-tools")
  tex.setup({ mappings = false })
  local config =
    vim.tbl_deep_extend("force", vim.deepcopy(vim.lsp.config.texlab), dofile(root .. "/after/lsp/texlab.lua"))
  config.name, config.root_dir = "texlab", directory
  config.settings.texlab.diagnosticsDelay = 50
  local analyzed = false
  config.handlers = {
    ["textDocument/publishDiagnostics"] = function(err, result, ctx, handler_config)
      vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx, handler_config)
      if not err and result and result.uri == vim.uri_from_fname(source) then
        analyzed = true
      end
    end,
  }
  local build = config.settings.texlab.build
  assert(build.executable == "latexmk" and build.onSave and not vim.list_contains(build.args, "-pvc"))
  local id = assert(vim.lsp.start(config))
  client = assert(vim.lsp.get_client_by_id(id))
  assert(
    vim.wait(10000, function()
      return client.initialized and vim.lsp.buf_is_attached(0, id)
    end, 10),
    "texlab did not initialize"
  )
  -- Initialization precedes texlab's asynchronous workspace/configuration pull.
  -- Wait until the server has analyzed this document with its loaded settings.
  assert(
    vim.wait(10000, function()
      return analyzed
    end, 10),
    "texlab did not analyze the document"
  )
  -- Count real build progress notifications and explicit build requests.
  local builds, requests = 0, 0
  vim.api.nvim_create_autocmd("LspProgress", {
    callback = function(event)
      local value = ((event.data.params or {}).value or {})
      if event.data.client_id == id and value.kind == "begin" and value.title == "Building" then
        builds = builds + 1
      end
    end,
  })
  local request = client.request
  client.request = function(self, method, ...)
    if method == "textDocument/build" then
      requests = requests + 1
    end
    return request(self, method, ...)
  end
  local function wait_build(previous, require_artifacts)
    assert(
      vim.wait(30000, function()
        return builds > previous and tex.build_status().phase == "finished"
      end, 20),
      "Save did not complete a build: " .. vim.inspect(tex.build_status())
    )
    if require_artifacts ~= false then
      assert(vim.fn.filereadable(directory .. "/build/main.pdf") == 1, "Missing PDF")
      assert(vim.fn.filereadable(directory .. "/build/main.synctex.gz") == 1, "Missing SyncTeX")
    end
  end
  text[3] = "Built from save."
  vim.api.nvim_buf_set_lines(0, 0, -1, false, text)
  vim.cmd.write()
  wait_build(0)
  assert(requests == 0, "Save unexpectedly sent an explicit build request")
  local previous = builds
  text[3] = "Built through the manual command with unsaved changes."
  vim.api.nvim_buf_set_lines(0, 0, -1, false, text)
  assert(tex.build())
  wait_build(previous)
  vim.wait(500, function()
    return false
  end, 20)
  assert(builds == previous + 1 and requests == 0, "Manual build duplicated the on-save build")
  assert(not vim.bo.modified and vim.fn.readfile(source)[3] == text[3])
  local info = assert(tex.project_info())
  assert(info.main_file == source and info.pdf_file == directory .. "/build/main.pdf")

  -- Real compiler errors must reach texlab's native diagnostic namespace.
  local function errors()
    return vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
  end
  previous = builds
  text[3] = "\\undefinedtestcommand This document has an error."
  vim.api.nvim_buf_set_lines(0, 0, -1, false, text)
  vim.cmd.write()
  wait_build(previous, false)
  assert(
    vim.wait(10000, function()
      for _, diagnostic in ipairs(errors()) do
        if diagnostic.message:find("Undefined control sequence", 1, true) then
          return true
        end
      end
      return false
    end, 10),
    "Compiler errors did not reach native diagnostics"
  )
  previous = builds
  text[3] = "The error is fixed."
  vim.api.nvim_buf_set_lines(0, 0, -1, false, text)
  vim.cmd.write()
  wait_build(previous)
  assert(
    vim.wait(10000, function()
      return #errors() == 0
    end, 10),
    "Fixed compiler errors stayed visible"
  )

  -- Invoke the native callback in a second Neovim and route through real RPC.
  local callback = assert(tex.inverse_search_command("skim"))
  callback.argv[#callback.argv - 1], callback.argv[#callback.argv] = "3", source
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  local result
  vim.system(callback.argv, { text = true }, function(output)
    result = output
  end)
  assert(
    vim.wait(10000, function()
      return result ~= nil
    end, 10),
    "Inverse callback timed out"
  )
  assert(result.code == 0, result.stderr)
  assert(vim.api.nvim_buf_get_name(0) == source and vim.api.nvim_win_get_cursor(0)[1] == 3)
  print(
    "Live LaTeX passed: save -> texlab -> latexmk -> PDF/SyncTeX, deduplicated manual build, compiler diagnostics/clearing, native inverse RPC"
  )
end
local ok, err = xpcall(check, debug.traceback)
if client then
  client:stop(true)
  vim.wait(2000, function()
    return client:is_stopped()
  end, 10)
end
if ok then
  vim.fn.delete(directory, "rf")
end
if not ok then
  io.stderr:write(err .. "\nArtifacts: " .. directory .. "\n")
  vim.cmd("cquit 1")
end
vim.cmd("qa!")
