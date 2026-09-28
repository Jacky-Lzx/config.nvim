local M = {}

M.profiles = require("config.profiles")

M.enabled_profiles = require("config.selection").profiles

M.lsp_servers = {
  bash = { "bashls" },
  cmake = { "cmake" },
  cpp = { "clangd" },
  godot = { "gdscript" },
  html = { "superhtml" },
  java = { "jdtls" },
  json = { "jsonls" },
  latex = { "texlab" },
  lua = { "lua_ls" },
  markdown = { "marksman", "harper_ls", "typos_lsp" },
  matlab = { "matlab_ls" },
  python = { "basedpyright" },
  rust = { "rust_analyzer" },
  swift = { "sourcekit" },
  toml = { "taplo" },
  typst = { "tinymist" },
  verilog = { "verible" },
  vue = { "vtsls", "vue_ls" },
  yaml = { "yamlls" },
}

local function collect(source)
  local result, seen = {}, {}
  for _, profile in ipairs(M.enabled_profiles) do
    for _, language in ipairs(M.profiles[profile] or {}) do
      local values = source and (source[language] or {}) or { language }
      for _, value in ipairs(values or {}) do
        if not seen[value] then
          seen[value] = true
          result[#result + 1] = value
        end
      end
    end
  end
  return result
end

function M.enabled_languages()
  return collect()
end

function M.is_enabled(language)
  return vim.list_contains(M.enabled_languages(), language)
end

function M.enabled_lsp_servers()
  return collect(M.lsp_servers)
end

return M
