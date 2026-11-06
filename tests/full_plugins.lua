-- Test-only opt-in to exercise optional integrations without editing the user's
-- per-plugin enabled flags. Never loaded by production configuration.
if vim.env.NVIM_TEST_ENABLE_THIRD_PARTY ~= "1" or _G.full_plugins_fixture then
  return
end
_G.full_plugins_fixture = true
local root = assert(vim.env.NVIM_CONFIG_ROOT)
local modules = {
  ["plugins.ui.nvim-web-devicons"] = { "nvim-web-devicons" },
  ["plugins.coding.conform"] = { "conform.nvim" },
  ["plugins.coding.nvim-lint"] = { "nvim-lint" },
  ["plugins.integrations.wakatime"] = { "vim-wakatime" },
  ["plugins.debugging.nvim-dap"] = { "nvim-dap", "nvim-dap-view" },
  ["languages.rust.plugins"] = { "crates.nvim" },
  ["languages.markdown.specs.render"] = { "render-markdown.nvim" },
  ["languages.markdown.specs.preview"] = { "peek.nvim" },
  ["languages.markdown.specs.obsidian"] = { "obsidian.nvim" },
  ["languages.typst"] = { "typst-preview.nvim" },
  ["languages.latex.plugins"] = { "texpresso.vim" },
}
for name, ids in pairs(modules) do
  local module_name, enabled_ids = name, ids
  package.preload[module_name] = function()
    local value = assert(loadfile(root .. "/lua/" .. module_name:gsub("%.", "/") .. ".lua"))()
    for _, spec in ipairs(value.plugins or value) do
      if vim.list_contains(enabled_ids, spec.id) then
        local executable = ({ ["peek.nvim"] = "deno", ["texpresso.vim"] = "texpresso" })[spec.id]
        spec.enabled = not executable or require("utils.platform").executable(executable) ~= nil
      end
    end
    return value
  end
end
