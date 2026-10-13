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
  local calls = 0
  require("lazy").load({ plugins = { "image-tools.nvim" } })
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
  assert(mapping.callback and mapping.desc == "[Image] Preview image under cursor")
  mapping.callback()
  assert(calls == 1, "Preview key must call the independent plugin")
  assert(vim.fn.exists(":ImagePreview") == 2, "Independent preview command missing")
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
