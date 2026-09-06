local M = {}

local platform = require("config.platform")
local languages = require("config.languages")

local function check_executable(name, required)
  local path = platform.executable(name)
  if path then
    vim.health.ok(('%s: "%s"'):format(name, path))
  elseif required then
    vim.health.error(("%s is not executable"):format(name))
  else
    vim.health.warn(("%s is not executable; related features will be unavailable"):format(name))
  end
end

local tools = {
  lua = { "lua-language-server", "stylua" },
  bash = { "bash-language-server", "shfmt" },
  json = { "vscode-json-language-server", "jq" },
  yaml = { "yaml-language-server" },
  toml = { "taplo" },
  kdl = { "kdlfmt" },
  html = { "superhtml", "html_beautify" },
  vue = { "vue-language-server", "vtsls", "npm" },
  cpp = { "clangd", "clang-format", "codelldb" },
  cmake = { "cmake-language-server", "cmake-format" },
  rust = { "rust-analyzer", "rustfmt", "cargo", "codelldb" },
  python = { "basedpyright", "ruff" },
  markdown = { "marksman", "harper-ls", "prettierd", "gh" },
  latex = { "texlab", "tex-fmt", "chktex", "latexmk", "tectonic" },
  typst = { "tinymist", "typstyle" },
  java = { "jdtls" },
  verilog = { "verible-verilog-ls", "verible-verilog-format", "iverilog" },
  godot = { "gdformat", "gdlint" },
  matlab = { "matlab-language-server", "mh_style" },
}

function M.check()
  vim.health.start("Neovim config")
  vim.health.info("Platform: " .. platform.os)
  vim.health.info("Enabled profiles: " .. table.concat(languages.enabled_profiles, ", "))

  check_executable("git", true)

  local shell = platform.shell()
  if shell then
    vim.health.ok('Shell: "' .. shell .. '"')
  else
    vim.health.error("No usable shell found; set NVIM_SHELL")
  end

  local opener = platform.opener()
  if opener then
    vim.health.ok("System opener: " .. table.concat(opener, " "))
  else
    vim.health.warn("No system opener found; set NVIM_OPEN_CMD")
  end

  local python = platform.python_host()
  if python then
    vim.health.ok('Python provider: "' .. python .. '"')
  else
    vim.health.warn("No explicit Python provider; set NVIM_PYTHON3_HOST_PROG if auto-discovery fails")
  end

  if languages.is_enabled("python") then
    local debugpy = platform.debugpy_python()
    if debugpy then
      vim.health.ok('debugpy Python: "' .. debugpy .. '"')
    else
      vim.health.warn("debugpy is unavailable; run :ConfigToolsInstall")
    end
  end

  vim.health.start("Optional integrations")
  for _, executable in ipairs({ "delta", "lazygit", "yazi", "kitty", "magick" }) do
    check_executable(executable, false)
  end
  if platform.is("macos") then
    if platform.skim_displayline() then
      vim.health.ok("Skim forward search is available")
    else
      vim.health.warn("Skim is unavailable; LaTeX preview will use zathura when available")
    end
  else
    check_executable("zathura", false)
  end

  local dev_root = platform.dev_plugin_root()
  if vim.uv.fs_stat(dev_root) then
    vim.health.ok('Local plugin root: "' .. dev_root .. '"')
  else
    vim.health.info('Local plugin root is absent; lazy.nvim will use Git fallback: "' .. dev_root .. '"')
  end

  vim.health.start("Enabled language tools")
  local seen = {}
  for _, language in ipairs(languages.enabled_languages()) do
    for _, executable in ipairs(tools[language] or {}) do
      if not seen[executable] then
        seen[executable] = true
        check_executable(executable, false)
      end
    end
  end
end

return M
