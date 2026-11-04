local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
require("config.context").initialize({ profiles = { "writing" }, features = {} })
vim.g.mapleader = " "
local api = vim.api
local integration = require("integrations.image_tools")
local loads, hovers, formulas = 0, 0, 0
local image_automatic = true
local registration
package.loaded.keymap_tools = {
  register = function(source, spec)
    assert(source == "image-tools.toggle")
    registration = spec.toggles[1]
  end,
}
package.preload.image_tools = function()
  loads = loads + 1
  return {
    status = function()
      return { auto_preview = image_automatic }
    end,
    hover = function()
      hovers = hovers + 1
    end,
    toggle = function()
      image_automatic = not image_automatic
      return image_automatic
    end,
  }
end
local formula_automatic = true
package.loaded["tex-tools"] = {
  formula_at = function()
    return {}
  end,
  preview_formula = function()
    formulas = formulas + 1
  end,
  formula_info = function()
    return { enabled = formula_automatic }
  end,
  toggle_formula_preview = function()
    formula_automatic = not formula_automatic
  end,
}
integration.setup({ auto_preview = true, math = { enabled = false } }, function()
  require("image_tools")
  integration.configured()
end)
assert(registration.get == integration.enabled and registration.get())
assert(loads == 0, "Reading automatic-preview state loaded the backend")
local function buffer(ft, lines)
  vim.cmd("enew!")
  api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.filetype = ft
end
local function cold()
  vim.wait(20)
  assert(loads == 0 and not package.loaded.image_tools, "Unused image backend was activated")
end
buffer("tex", { "$x$" })
integration.preview()
assert(formulas == 1)
cold()
assert(integration.toggle() == false and not formula_automatic)
assert(not registration.get())
api.nvim_buf_set_lines(0, 0, -1, false, { "\\includegraphics{figure.png}" })
cold()
assert(integration.options({ position = "bottom_right" }).auto_preview == false)
buffer("markdown", { "$x$" })
assert(integration.toggle() == true)
cold()
-- An edit removed before activation must not initialize the provider.
api.nvim_buf_set_lines(0, 0, -1, false, { "![example](figure.png)" })
api.nvim_buf_set_lines(0, 0, -1, false, { "plain document" })
cold()
buffer("lua", { 'local text = "![not a document](figure.png)"' })
cold()
buffer("html", { "plain document" })
api.nvim_buf_set_lines(0, 0, -1, false, { '<img src="figure.png">' })
assert(integration.toggle() == false)
cold()
assert(integration.toggle() == true)
assert(
  vim.wait(500, function()
    return loads == 1
  end),
  "Editing an image reference did not activate automatic preview"
)
integration.preview()
assert(hovers == 1 and loads == 1)
-- A provider can also be toggled by its own command; do not infer its state
-- from the integration's previous automatic-preview flag.
image_automatic = false
assert(not registration.get(), "Status ignored the backend command state")
assert(integration.toggle() == true)
assert(registration.get())
assert(integration.toggle() == false)
assert(vim.fn.exists("#ConfigImageActivation") == 0)
print("Image activation: plain text, disabled preview, formula dispatch, stale edits and first reference passed")
