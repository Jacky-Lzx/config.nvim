local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
require("config.context").initialize({ profiles = { "writing" }, features = {} })
vim.g.mapleader = " "
local registration, automatic, hovers, formulas, loads = nil, true, 0, 0, 0
package.loaded.keymap_tools = {
  register = function(_, spec)
    registration = spec.toggles[1]
  end,
}
package.loaded["image_tools.bootstrap"] = {
  enabled = function()
    return automatic
  end,
  toggle = function()
    automatic = not automatic
    return automatic
  end,
  ensure = function()
    loads = loads + 1
    return {
      hover = function()
        hovers = hovers + 1
      end,
    }
  end,
}
local at_formula = true
package.loaded["tex-tools"] = {
  formula_at = function()
    return at_formula
  end,
  preview_formula = function()
    formulas = formulas + 1
  end,
  formula_info = function()
    return { enabled = automatic }
  end,
  toggle_formula_preview = function() end,
}
local integration = require("integrations.image_tools")
integration.setup()
assert(registration.get == integration.enabled and registration.get())
vim.bo.filetype = "tex"
integration.preview()
assert(formulas == 1 and loads == 0, "Formula selection activated the image backend")
assert(integration.toggle() == false and not registration.get())
assert(loads == 0, "Toggling automatic preview requested an image provider")
assert(integration.toggle() == true)
at_formula = false
integration.preview()
assert(hovers == 1 and loads == 1)
automatic = false
assert(not registration.get(), "Status ignored plugin-owned state")
assert(integration.toggle() == true)
print("Personal image/formula dispatch and plugin-owned automatic state passed")
