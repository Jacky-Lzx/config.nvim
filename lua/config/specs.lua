local M = {}

function M.build(selection)
  local context = selection and require("config.context").initialize(selection) or require("config.context").current()
  local optional = require("config.features").names

  local specs = {}
  for _, group in ipairs({ "ui", "editing", "navigation", "coding", "git", "integrations" }) do
    specs[#specs + 1] = { import = "plugins." .. group }
  end
  for _, group in ipairs(optional) do
    if context.selection.features[group] then
      specs[#specs + 1] = { import = "plugins." .. group }
    end
  end
  vim.list_extend(specs, vim.deepcopy(context.languages.plugins))
  return specs
end

return M
