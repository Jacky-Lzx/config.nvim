local api = vim.api
local case = assert(vim.env.NVIM_STARTUP_CASE)
local temp = assert(vim.env.NVIM_TEST_TMP)
local plugins = require("config.plugins").nodes()
local image_spec = assert(plugins["image-tools.nvim"])
local function active()
  local image = package.loaded.image_tools
  return image ~= nil and image.status().configured
end
local function cold()
  assert(not active() and not package.loaded.image_tools, "Image backend loaded before image demand")
end
local function feed(keys)
  api.nvim_feedkeys(vim.keycode(keys), "xt", false)
end
local function document(ft, text)
  vim.cmd("enew!")
  api.nvim_buf_set_lines(0, 0, -1, false, { text or "plain document" })
  vim.bo.filetype = ft
end
local function pixel()
  local path = temp .. "/pixel.PNG"
  local png =
    vim.base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")
  local file = assert(io.open(path, "wb"))
  file:write(png)
  file:close()
  return path
end
local function automatic_request()
  local request
  require("image_tools.runtime").open_preview = function(_, path, opts)
    request = { path = path, automatic = opts.automatic }
    return true
  end
  return function()
    assert(
      vim.wait(2000, function()
        return request ~= nil
      end),
      "Automatic preview was not requested after activation"
    )
    assert(request.automatic)
    return request.path
  end
end
local function check()
  assert(vim.g.config_ready, "This test requires the real terminal startup lifecycle")
  cold()
  assert(next(plugins["tex-tools.nvim"].dependencies) == nil)
  for name in pairs(plugins["lsp-tools.nvim"].dependencies) do
    assert(
      name ~= "image-tools.nvim" and name ~= "git-tools.nvim" and name ~= "selection-tools.nvim",
      "LSP setup must keep image, diff and picker backends deferred"
    )
  end
  if case == "image_plain" then
    for _, ft in ipairs({ "markdown", "tex", "plaintex", "typst", "html" }) do
      document(ft)
      vim.wait(50)
      cold()
    end
    api.nvim_exec_autocmds("BufReadPre", { buffer = 0 })
    assert(require("config.plugins").initialized("lsp-tools.nvim"))
    assert(not package.loaded["git_tools.diff.render"], "LSP setup must not initialize the optional diff renderer")
  elseif case == "image_edit" then
    document("markdown", "")
    cold()
    feed("i![example](missing.png)<Esc>")
    assert(
      vim.wait(1000, function()
        return active()
      end),
      "Typing an image reference did not initialize automatic preview"
    )
    assert(require("image_tools").status().auto_preview)
  elseif case == "image_existing" then
    pixel()
    local displayed = automatic_request()
    local path = temp .. "/image-document.html"
    vim.fn.writefile({ '<img src="pixel.PNG">' }, path)
    vim.cmd.edit(path)
    assert(
      vim.wait(1000, function()
        return active()
      end),
      "Opening a document with an image did not initialize automatic preview"
    )
    assert(displayed():match("/pixel%.PNG$"))
  elseif case == "image_markdown_formula" then
    local displayed = automatic_request()
    document("markdown", "$x$")
    assert(displayed():find("math:", 1, true), "Markdown formula preview was lost")
  elseif case == "image_tex_reference" then
    document("tex")
    api.nvim_buf_set_name(0, temp .. "/image-document.tex")
    local tex = require("tex-tools")
    api.nvim_buf_set_lines(0, 0, -1, false, { "\\includegraphics{missing.png}" })
    local ok, err = tex.preview()
    assert(not ok and err:find("Image not found", 1, true), tostring(err))
    cold()
    local request
    require("image_tools.runtime").float = function(_, opts)
      request = opts
      return {
        close = function() end,
        status = function()
          return { stage = "ready" }
        end,
      }
    end
    local path = pixel()
    api.nvim_buf_set_lines(0, 0, -1, false, { "\\includegraphics{" .. path .. "}" })
    api.nvim_exec_autocmds("TextChanged", { buffer = 0 })
    assert(
      vim.wait(2000, function()
        return request ~= nil
      end),
      "Valid TeX image did not reach the display backend"
    )
    assert(request.path == path and request.is_valid(), "TeX preview selected the wrong image")
    assert(tex.formula_info().kind == "image" and active())
    tex.close_formula_preview()
  elseif case == "image_typst_reference" then
    document("typst")
    cold()
    api.nvim_buf_set_lines(0, 0, -1, false, { '#image("missing.png")' })
    assert(
      vim.wait(1000, function()
        return active()
      end),
      "An edited Typst image reference did not initialize automatic preview"
    )
  elseif case == "image_disabled" then
    document("tex")
    feed(" ui")
    assert(not require("tex-tools").formula_info().enabled)
    cold()
    api.nvim_buf_set_lines(0, 0, -1, false, { "\\includegraphics{missing.png}" })
    vim.wait(150)
    cold()
    vim.cmd("ImagePreviewClose")
    assert(active() and not require("image_tools").status().auto_preview)
  elseif case == "image_formula" then
    -- Disable automatic formula requests so this test controls the first manual
    -- display. The real controller/parser and Lazy provider setup still run.
    local opts = vim.deepcopy((plugins["tex-tools.nvim"]).opts)
    opts.formula_preview.enabled = false
    require("config.plugins").manager:use("tex-tools.nvim").setup(opts)
    document("tex", "$x$")
    vim.treesitter.get_parser(0, "latex"):parse()
    api.nvim_win_set_cursor(0, { 1, 1 })
    local complete
    require("tex-tools.formula.render").prepare = function(_, _, callback)
      complete = callback
      return function() end
    end
    local displayed = 0
    require("image_tools.runtime").float = function()
      displayed = displayed + 1
      return {
        close = function() end,
        status = function()
          return { stage = "ready" }
        end,
      }
    end
    feed(" si")
    assert(complete, "First preview key did not reach the formula compiler")
    cold()
    complete(nil, { path = temp .. "/formula.png", release = function() end })
    assert(active() and displayed == 1, "Completed formula did not initialize and use its provider")
    assert(require("image_tools").status().configured)
    require("tex-tools").close_formula_preview()
  elseif case == "image_file" then
    vim.cmd.edit(pixel())
    assert(active(), "First binary-file read did not initialize image-tools")
    assert(vim.bo.buftype == "nofile", "Binary bytes were opened as an ordinary editable document")
  else
    error("Unknown image loading case: " .. case)
  end
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
end
local function run()
  local ok, err = xpcall(check, debug.traceback)
  vim.fn.writefile(vim.split(ok and ("Image loading TUI passed: " .. case) or err, "\n"), vim.env.NVIM_STARTUP_RESULT)
  vim.cmd(ok and "quitall!" or "cquit 1")
end
if vim.g.config_ready then
  vim.schedule(run)
else
  api.nvim_create_autocmd("User", {
    pattern = "ConfigReady",
    once = true,
    callback = function()
      vim.schedule(run)
    end,
  })
end
