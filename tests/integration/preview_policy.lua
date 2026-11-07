local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
dofile(root .. "/tests/support/setup.lua")
dofile(root .. "/init.lua")
dofile(root .. "/tests/support/native_plugins.lua")
local policy = require("integrations.image_tools")
assert(not package.loaded["tex-tools"] and not package.loaded.image_tools)
policy.set_enabled(false)
policy.set_enabled(false)
assert(not package.loaded["tex-tools"] and not package.loaded.image_tools)
vim.cmd("filetype plugin indent on")
local path = vim.env.NVIM_TEST_TMP .. "/policy.tex"
vim.fn.writefile({ "\\documentclass{article}", "\\begin{document}", "plain text", "\\end{document}" }, path)
vim.cmd.edit(path)
local tex = require("tex-tools")
local tex_buf = vim.api.nvim_get_current_buf()
local bootstrap = require("image_tools.bootstrap")
local set_automatic = bootstrap.set_auto_preview
bootstrap.set_auto_preview = function(state)
  assert(
    vim.b[tex_buf].image_tools_preview_owner == (state and "tex-tools" or nil),
    "Generic activation observed stale TeX ownership"
  )
  return set_automatic(state)
end
assert(not tex.formula_info().enabled and not tex.formula_info().images_enabled)
local snapshot = require("config.inspect").snapshot().integrations.preview
assert(snapshot.automatic == false and snapshot.tex.enabled == false and not snapshot.renderer_loaded)
vim.cmd.enew()
vim.bo.filetype = "lua"
policy.set_enabled(true)
assert(tex.formula_info().enabled and tex.formula_info().images_enabled)
policy.set_enabled(true)
assert(tex.formula_info().enabled)
policy.set_enabled(false)
assert(not tex.formula_info().enabled and not tex.formula_info().images_enabled)
assert(not package.loaded.image_tools and not package.loaded["tex-tools.formula.render"])
print("Preview policy: cold inheritance, cross-filetype synchronization and idempotence passed")
