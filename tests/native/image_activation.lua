local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
require("config.context").initialize({ profiles = { "writing" }, features = {} })
vim.g.mapleader = " "
local registration, automatic, formula_enabled, hovers, previews, loads = nil, true, true, 0, 0, 0
package.loaded.keymap_tools = {
  register = function(_, spec)
    registration = spec.toggles[1]
  end,
}
package.loaded["image_tools.bootstrap"] = {
  enabled = function()
    return automatic
  end,
  set_auto_preview = function(value)
    automatic = value
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
package.loaded["tex-tools"] = {
  preview = function()
    previews = previews + 1
    return "tex-preview"
  end,
  formula_info = function()
    return { enabled = formula_enabled }
  end,
  set_auto_preview = function(value)
    formula_enabled = value
  end,
}
local integration = require("integrations.image_tools")
integration.setup()
assert(registration.get({}) == integration.enabled() and registration.get({}))
for _, ft in ipairs({ "tex", "plaintex", "latex" }) do
  vim.bo.filetype = ft
  assert(integration.preview() == "tex-preview", "TeX preview result must pass through")
end
assert(previews == 3 and loads == 0, "TeX preview dispatch must stay inside tex-tools")
assert(integration.toggle() == false and not registration.get({}))
assert(not formula_enabled, "Automatic image and formula preview state must agree")
assert(loads == 0, "Toggling automatic preview requested an image provider")
assert(integration.toggle() == true)
assert(formula_enabled)
vim.bo.filetype = "markdown"
integration.preview()
assert(hovers == 1 and loads == 1)
assert(previews == 3, "Non-TeX files must use the generic image provider")
automatic = false
assert(not registration.get({}), "Status ignored plugin-owned state")
assert(integration.toggle() == true)
assert(
  formula_enabled and loads == 1,
  "Non-TeX toggles must synchronize already-loaded controllers without activating providers"
)
integration.set_enabled(false)
assert(not automatic and not formula_enabled)
integration.set_enabled(false)
assert(not automatic and not formula_enabled, "Repeated set toggled state")
integration.set_enabled(true)
local notices, notify = {}, vim.notify
vim.notify = function(message)
  notices[#notices + 1] = message
end
local mapping = vim.fn.maparg("<leader>tia", "n", false, true).callback
mapping()
assert(not registration.get({}) and notices[1] == "Automatic image preview: Disabled")
mapping()
assert(registration.get({}) and notices[2] == "Automatic image preview: Enabled" and #notices == 2)
vim.notify = notify
print("Personal TeX/generic preview dispatch and plugin-owned automatic state passed")
