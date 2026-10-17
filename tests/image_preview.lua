local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
require("config.context").initialize({ profiles = {}, features = {} })
vim.g.loaded_wakatime = true
vim.o.loadplugins = true
dofile(root .. "/init.lua")
local plugins = require("lazy.core.config").plugins
local snacks = require("lazy.core.plugin").values(plugins["snacks.nvim"], "opts", false)
assert(snacks.image.enabled == false, "Snacks image must be disabled")
local expected = require("utils.platform").dev_plugin_root() .. "/image-tools.nvim"
local spec = plugins["image-tools.nvim"]
local available = vim.uv.fs_stat(expected .. "/lua/image_tools/init.lua") ~= nil
if available then
  assert(spec, "Independent preview spec missing")
  assert(spec.dir == expected, "Independent preview must use the external checkout")
  assert(
    require("lazy.core.plugin").values(spec, "opts", false).position == "bottom_right",
    "Preview must be configured for the bottom-right corner"
  )
  local options = require("lazy.core.plugin").values(spec, "opts", false)
  assert(options.transport == "auto", "Preview should prefer file transfer with automatic direct fallback")
  assert(spec.lazy == true, "Image preview must load on demand")
  assert(not spec._.loaded and not package.loaded.image_tools, "Empty startup must leave image preview unloaded")
  local calls = 0
  vim.cmd("ImagePreviewClose")
  assert(spec._.loaded, "Independent preview did not load")
  local image = require("image_tools")
  assert(
    debug.getinfo(image.hover).source:find(expected, 1, true),
    "Preview source was vendored or resolved incorrectly"
  )
  image.hover = function()
    calls = calls + 1
  end
  local mapping = vim.fn.maparg(vim.g.mapleader .. "si", "n", false, true)
  assert(mapping.callback and mapping.desc == "[Image] Preview image on current line")
  mapping.callback()
  assert(calls == 1, "Preview key must call the independent plugin")
  assert(not plugins["image-insert.nvim"], "Old image insertion plugin must be removed")
  assert(type(snacks.picker.preview) == "function", "Independent picker preview bridge missing")
  assert(
    vim.fn.exists(":ImageOpen") == 2 and vim.fn.exists(":ImagePage") == 2,
    "Image/PDF file buffer commands missing"
  )
  assert(vim.fn.exists(":ImagePick") == 2, "Independent picker command missing")
  assert(vim.fn.exists(":ImagePaste") == 2, "Independent clipboard command missing")
  assert(vim.fn.exists(":ImageInsert") == 2, "Independent image import command missing")
  dofile(root .. "/tests/image_insertion.lua")
  assert(vim.fn.exists(":ImagePreview") == 2, "Independent preview command missing")
  assert(vim.fn.exists(":ImagePreviewClearCache") == 2, "Terminal cache cleanup command missing")
else
  assert(not spec or spec.cond == false, "Missing unpublished plugin should be disabled without cloning")
end
assert(package.loaded["snacks.image"] == nil, "Snacks image was loaded despite being disabled")
print(
  "image_preview: independent local plugin "
    .. (available and "loaded" or "gracefully absent")
    .. ", Snacks image disabled"
)
vim.cmd("qa!")
