local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
require("config.context").initialize({ profiles = {}, features = {} })
vim.g.loaded_wakatime = true
vim.o.loadplugins = true
dofile(root .. "/init.lua")
local plugins = require("lazy.core.config").plugins
local dev = require("utils.platform").dev_plugin_root()
local available = vim.uv.fs_stat(dev .. "/pdf-view.nvim/lua/pdf_view/init.lua")
local spec = plugins["pdf-view.nvim"]
if available then
  assert(spec and spec._.loaded and spec.dir == dev .. "/pdf-view.nvim", "External PDF reader did not load")
  assert(not spec.dependencies or #spec.dependencies == 0, "PDF reader must not depend on another plugin")
  assert(vim.fn.exists(":PdfOpen") == 2 and vim.fn.exists(":PdfFit") == 2)
  if plugins["image-tools.nvim"] and plugins["image-tools.nvim"].cond ~= false then
    local image_opts = require("lazy.core.plugin").values(plugins["image-tools.nvim"], "opts", false)
    assert(not vim.tbl_contains(image_opts.buffer.formats, "pdf"), "Two plugins own PDF interception")
  else
    for name in pairs(package.loaded) do
      assert(name ~= "image_tools" and not name:match("^image_tools%."), "Standalone PDF startup loaded image-tools")
    end
  end
  local owners = 0
  for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = "BufReadCmd" })) do
    if autocmd.pattern == "*.pdf" then
      owners = owners + 1
    end
  end
  assert(owners == 1, "PDF must have exactly one file interceptor")
  local path = assert(vim.env.NVIM_TEST_TMP) .. "/reader.pdf"
  vim.fn.writefile({ "%PDF-1.4" }, path)
  vim.cmd.edit(path)
  assert(vim.bo.filetype == "pdf_view" and not vim.bo.modifiable and vim.bo.readonly)
  assert(not pcall(vim.cmd, "write!"), "PDF file is writable")
  if vim.env.PDF_READER_ISOLATED ~= "1" then
    local isolated = vim.fn.tempname() .. "-pdf-reader-only"
    vim.fn.mkdir(isolated, "p")
    assert(vim.uv.fs_symlink(dev .. "/pdf-view.nvim", isolated .. "/pdf-view.nvim"))
    local result = vim
      .system({
        vim.v.progpath,
        "--headless",
        "-u",
        "NONE",
        "-i",
        "NONE",
        "--noplugin",
        "-l",
        root .. "/tests/pdf_reader.lua",
      }, {
        text = true,
        env = { NVIM_DEV_PLUGIN_ROOT = isolated, PDF_READER_ISOLATED = "1", NVIM_TEST_TMP = isolated },
      })
      :wait(10000)
    vim.uv.fs_unlink(isolated .. "/pdf-view.nvim")
    vim.fn.delete(isolated, "rf")
    assert(result.code == 0, "PDF startup without image-tools failed: " .. (result.stderr or result.stdout or ""))
  end
else
  assert(not spec or spec.cond == false, "Missing unpublished reader must be disabled")
  if plugins["image-tools.nvim"] and plugins["image-tools.nvim"].cond ~= false then
    local options = require("lazy.core.plugin").values(plugins["image-tools.nvim"], "opts", false)
    assert(not options.buffer or vim.tbl_contains(options.buffer.formats, "pdf"), "Fallback PDF viewer was disabled")
  end
end
print("pdf_reader: " .. (available and "external reader owns PDF buffers" or "missing checkout handled"))
vim.cmd("qa!")
