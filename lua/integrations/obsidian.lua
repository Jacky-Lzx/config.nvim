local M = {}

-- Obsidian is enabled only by explicit project workspaces. Workspace lists use
-- the same last-declaration replacement rule as plugin-tools option merging.
function M.specs(specs)
  local workspaces
  for _, spec in ipairs(specs) do
    if spec.id == "obsidian.nvim" and spec.enabled ~= false and spec.opts and spec.opts.workspaces ~= nil then
      workspaces = spec.opts.workspaces
    end
  end
  if type(workspaces) ~= "table" or #workspaces == 0 then
    return vim.tbl_filter(function(spec)
      return spec.id ~= "obsidian.nvim"
    end, specs)
  end
  local result = vim.list_extend({}, specs)
  result[#result + 1] = {
    id = "image-tools.nvim",
    origin = "integrations.obsidian",
    opts = { insert = { directory = "assets/imgs" } },
  }
  return result
end

return M
