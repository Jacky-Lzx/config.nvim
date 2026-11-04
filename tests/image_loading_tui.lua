local api = vim.api
local case = assert(vim.env.NVIM_LAZY_CASE)
local temp = assert(vim.env.NVIM_TEST_TMP)
local plugins = require("lazy.core.config").plugins
local image_spec = assert(plugins["image-tools.nvim"])
local function cold()
  assert(not image_spec._.loaded and not package.loaded.image_tools, "Image backend loaded before image demand")
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
  local configured, request = image_spec.config, nil
  image_spec.config = function(plugin, options)
    -- Observe the real automatic lookup/delay path without terminal graphics.
    require("image_tools.runtime").open_preview = function(_, path, opts)
      request = { path = path, automatic = opts.automatic }
      return true
    end
    configured(plugin, options)
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
  assert(vim.g.did_very_lazy, "This test requires the real terminal startup lifecycle")
  cold()
  assert(not plugins["tex-tools.nvim"].dependencies)
  assert(not plugins["lsp-tools.nvim"].dependencies)
  if case == "image_plain" then
    for _, ft in ipairs({ "markdown", "tex", "plaintex", "typst", "html" }) do
      document(ft)
      vim.wait(50)
      cold()
    end
    api.nvim_exec_autocmds("LspAttach", { buffer = 0, data = { client_id = 999999 } })
    assert(plugins["lsp-tools.nvim"]._.loaded)
    assert(not plugins["git-tools.nvim"]._.loaded, "LSP setup must not initialize its optional diff backend")
  elseif case == "image_edit" then
    document("markdown", "")
    cold()
    feed("i![example](missing.png)<Esc>")
    assert(
      vim.wait(1000, function()
        return image_spec._.loaded ~= nil
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
        return image_spec._.loaded ~= nil
      end),
      "Opening a document with an image did not initialize automatic preview"
    )
    assert(displayed():match("/pixel%.PNG$"))
  elseif case == "image_markdown_formula" then
    local displayed = automatic_request()
    document("markdown", "$x$")
    assert(displayed():find("math:", 1, true), "Markdown formula preview was lost")
  elseif case == "image_tex_reference" or case == "image_typst_reference" then
    local ft = case == "image_tex_reference" and "tex" or "typst"
    document(ft)
    cold()
    api.nvim_buf_set_lines(0, 0, -1, false, {
      ft == "tex" and "\\includegraphics[width=\\linewidth]{missing.png}" or '#image("missing.png")',
    })
    assert(
      vim.wait(1000, function()
        return image_spec._.loaded ~= nil
      end),
      "An edited " .. ft .. " image reference did not initialize automatic preview"
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
    assert(image_spec._.loaded and not require("image_tools").status().auto_preview)
  elseif case == "image_formula" then
    -- Disable automatic formula requests so this test controls the first manual
    -- display. The real controller/parser and Lazy provider setup still run.
    local opts = require("lazy.core.plugin").values(plugins["tex-tools.nvim"], "opts", false)
    opts.formula_preview.enabled = false
    document("tex", "$x$")
    vim.treesitter.get_parser(0, "latex"):parse()
    api.nvim_win_set_cursor(0, { 1, 1 })
    local complete
    require("tex-tools.formula.render").prepare = function(_, _, callback)
      complete = callback
      return function() end
    end
    local configured, displayed = image_spec.config, 0
    image_spec.config = function(plugin, options)
      configured(plugin, options)
      require("image_tools").float = function()
        displayed = displayed + 1
        return {
          close = function() end,
          status = function()
            return { stage = "ready" }
          end,
        }
      end
    end
    feed(" si")
    assert(complete, "First preview key did not reach the formula compiler")
    cold()
    complete(nil, { path = temp .. "/formula.png", release = function() end })
    assert(image_spec._.loaded and displayed == 1, "Completed formula did not initialize and use its provider")
    assert(require("image_tools").status().configured)
    require("tex-tools").close_formula_preview()
  elseif case == "image_file" then
    vim.cmd.edit(pixel())
    assert(image_spec._.loaded, "First binary-file read did not initialize image-tools")
    assert(vim.bo.buftype == "nofile", "Binary bytes were opened as an ordinary editable document")
  else
    error("Unknown image loading case: " .. case)
  end
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
end
local function run()
  local ok, err = xpcall(check, debug.traceback)
  vim.fn.writefile(vim.split(ok and ("Image loading TUI passed: " .. case) or err, "\n"), vim.env.NVIM_LAZY_RESULT)
  vim.cmd(ok and "quitall!" or "cquit 1")
end
if vim.g.did_very_lazy then
  vim.schedule(run)
else
  api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      vim.schedule(run)
    end,
  })
end
