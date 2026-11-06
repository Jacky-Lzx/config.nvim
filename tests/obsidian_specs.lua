vim.opt.rtp:prepend(assert(vim.env.NVIM_CONFIG_ROOT))
local resolve = require("integrations.obsidian").specs
local image = { id = "image-tools.nvim", opts = {} }
local function obsidian(workspaces, enabled)
  return { id = "obsidian.nvim", enabled = enabled, opts = { workspaces = workspaces } }
end
assert(vim.deep_equal(resolve({ image, obsidian(nil) }), { image }))
local specs = { image, obsidian({ { name = "vault", path = "/vault" } }) }
local result = resolve(specs)
assert(#specs == 2 and #result == 3, "Integration must not mutate declaration lists")
assert(result[3].opts.insert.directory == "assets/imgs" and result[3].origin == "integrations.obsidian")
assert(
  vim.deep_equal(resolve({ image, specs[2], obsidian({}) }), { image }),
  "An empty later workspace list must clear the vault"
)
assert(vim.deep_equal(resolve({ image, obsidian({ { path = "/disabled" } }, false) }), { image }))
print("Project Obsidian integration: absent/cleared/disabled workspaces, ordered contributions and cold images passed")
