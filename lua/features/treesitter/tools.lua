local M = {}

function M.status()
  local missing = {}
  for _, name in ipairs({ "curl", "tar", "tree-sitter" }) do
    if vim.fn.executable(name) == 0 then
      missing[#missing + 1] = name
    end
  end
  local compiler = vim.env.CC or "cc"
  if vim.fn.executable(compiler) == 0 then
    missing[#missing + 1] = compiler .. " (C compiler)"
  end
  local version
  if vim.fn.executable("tree-sitter") == 1 then
    local result = vim.system({ "tree-sitter", "--version" }, { text = true }):wait(5000)
    version = (result.stdout or ""):match("%d+%.%d+%.%d+")
    if result.code ~= 0 or not version or not vim.version.ge(version, "0.26.1") then
      missing[#missing + 1] = "tree-sitter-cli >= 0.26.1"
    end
  end
  return { available = #missing == 0, missing = missing, version = version }
end

return M
