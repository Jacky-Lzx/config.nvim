local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
require("config.context").initialize({ profiles = {}, features = {} })
vim.g.loaded_wakatime = true
vim.o.loadplugins = true
dofile(root .. "/init.lua")
local plugins = require("lazy.core.config").plugins
local dev = require("utils.platform").dev_plugin_root()
local available = vim.uv.fs_stat(dev .. "/pdf-view.nvim/lua/pdf_view/init.lua")
  and vim.uv.fs_stat(dev .. "/image-tools.nvim/lua/image_tools/init.lua")
local spec = plugins["pdf-view.nvim"]
if available then
  assert(spec and spec._.loaded and spec.dir == dev .. "/pdf-view.nvim", "External PDF reader did not load")
  assert(vim.fn.exists(":PdfOpen") == 2 and vim.fn.exists(":PdfFit") == 2)
  local image_opts = require("lazy.core.plugin").values(plugins["image-tools.nvim"], "opts", false)
  assert(not vim.tbl_contains(image_opts.buffer.formats, "pdf"), "Two plugins own PDF interception")
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
else
  assert(not spec or spec.cond == false, "Missing unpublished reader must be disabled")
  if plugins["image-tools.nvim"] and plugins["image-tools.nvim"].cond ~= false then
    local options = require("lazy.core.plugin").values(plugins["image-tools.nvim"], "opts", false)
    assert(not options.buffer or vim.tbl_contains(options.buffer.formats, "pdf"), "Fallback PDF viewer was disabled")
  end
end
print("pdf_reader: " .. (available and "external reader owns PDF buffers" or "missing checkout handled"))
vim.cmd("qa!")
