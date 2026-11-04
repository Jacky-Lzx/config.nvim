local M = {}

-- Project resolved language declarations without loading any installation backend.
function M.requirements(provider)
  local languages = require("languages").current()
  local requirements = {
    { provider = "parser", name = "regex" },
    { provider = "mason", name = "codespell", executable = "codespell" },
  }
  for _, name in ipairs(languages.parsers) do
    requirements[#requirements + 1] = { provider = "parser", name = name }
  end
  for _, tool in ipairs(languages.tools) do
    requirements[#requirements + 1] = {
      provider = tool.mason and "mason" or "system",
      name = tool.mason or tool.executable,
      executable = tool.executable,
      resolve = tool.resolve,
      post_install = tool.post_install,
      post_install_async = tool.post_install_async,
      optional = tool.optional,
    }
  end
  if provider then
    requirements = vim.tbl_filter(function(requirement)
      return requirement.provider == provider
    end, requirements)
  end
  return requirements
end

function M.install(provider)
  return require("toolchain").install(M.requirements(provider))
end

return M
