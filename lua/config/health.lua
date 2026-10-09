local M = {}

function M.check()
  local info = require("config").info()
  vim.health.start("Configuration")

  if vim.fn.has("nvim-0.12") == 1 then
    vim.health.ok("Neovim " .. info.version)
  else
    vim.health.error("Neovim 0.12 or newer is required")
  end

  local entry = vim.fs.joinpath(info.paths.config, "init.lua")
  if vim.fn.filereadable(entry) == 1 then
    vim.health.ok("Configuration entry: " .. entry)
  else
    vim.health.warn("No init.lua at the standard configuration path: " .. entry)
  end

  for _, name in ipairs({ "data", "state", "cache" }) do
    vim.health.info(name .. ": " .. info.paths[name])
  end

  vim.health.start("Plugins")
  if not info.plugins.enabled then
    vim.health.ok("Plugin features are disabled")
  elseif #info.plugins.missing > 0 then
    vim.health.warn("Missing plugins: " .. table.concat(info.plugins.missing, ", "), { "Run :ConfigPluginsInstall" })
  else
    vim.health.ok("Selected plugins are installed at " .. info.plugins.root)
  end
  for _, name in ipairs({
    "theme",
    "input",
    "picker",
    "treesitter",
    "textobjects",
    "git",
    "statusline",
    "buffers",
    "comments",
  }) do
    local feature = info.plugins.features[name]
    if feature.available then
      vim.health.ok(name .. " plugins are available")
    elseif not feature.enabled then
      vim.health.info(name .. " plugins are disabled")
    end
  end
  if info.plugins.features.input.available then
    local pairing = require("features.input.pairing").source()
    if pairing.available then
      vim.health.ok("Local pairs.nvim: " .. pairing.dir)
      if vim.fn.executable("git") == 1 then
        local result = vim.system({ "git", "-C", pairing.dir, "rev-parse", "HEAD" }, { text = true }):wait()
        if result.code == 0 then
          vim.health.info("Local pairing revision: " .. vim.trim(result.stdout))
        end
      end
    else
      vim.health.warn("Local pairs.nvim is unavailable; completion and native newline remain available")
      vim.health.info("Set NVIM_DEV_PLUGIN_ROOT to the parent directory of the pairs.nvim checkout")
    end
  end

  if info.plugins.features.picker.enabled then
    require("features.picker.tools").check()
  end

  require("features.treesitter.health").check()
  require("features.textobjects").check()
  require("features.git").check()
  require("features.ui.icons").check()

  vim.health.start("Language servers")
  if not info.lsp.enabled then
    vim.health.ok("Language features are disabled")
  elseif #info.lsp.servers == 0 then
    vim.health.info("No languages selected")
  else
    for _, server in ipairs(info.lsp.servers) do
      if server.available then
        vim.health.ok(server.name .. ": " .. vim.fn.exepath(server.executable))
      else
        vim.health.warn(server.name .. " is unavailable", { "Install " .. server.executable .. " and restart Neovim" })
      end
    end
  end
end

return M
