-- Temporary personal policy for standalone third-party plugins. Set enabled=true (or NVIM_THIRD_PARTY_PLUGINS=1)
-- before startup to restore the original third-party declarations.
local M = { enabled = vim.env.NVIM_THIRD_PARTY_PLUGINS == "1" }

local function owned(spec)
  if spec.source then
    local source = spec.source:lower()
    return source:match("^jacky%-lzx/") or source:match("github%.com[:/]jacky%-lzx/")
  end
  local root = vim.fs.normalize(require("utils.platform").dev_plugin_root())
  local dir = vim.fs.normalize(vim.fn.expand(spec.dir))
  return vim.startswith(dir, root .. "/")
end

local function visit(specs, callback, parent)
  for _, spec in ipairs(specs) do
    callback(spec, parent)
    visit(spec.children or {}, callback, spec)
  end
end

function M.apply(specs)
  if M.enabled then
    return specs
  end
  local disabled = {}
  visit(specs, function(spec, parent)
    -- Dependencies declared beneath an owned plugin remain available.
    -- Theme/icon providers managed internally by theme-tools are unaffected.
    local internal = parent and (parent.source or parent.dir) and owned(parent)
    if (spec.source or spec.dir) and not owned(spec) and not internal then
      disabled[spec.id] = true
    end
  end)
  visit(specs, function(spec)
    if disabled[spec.id] then
      -- Disable option-only contributions too; they must not recreate a node.
      spec.enabled = false
    end
  end)
  return specs
end

return M
