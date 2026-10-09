local M = {}

function M.requirements()
  return { { "mini.ai", "lua/mini/ai.lua" } }
end

function M.specs()
  return {
    {
      "nvim-mini/mini.ai",
      lazy = vim.g.config_plugin_install and true or false,
      opts = function()
        return require("features.textobjects.options").get()
      end,
      config = function(_, opts)
        require("mini.ai").setup(opts)
      end,
    },
  }
end

function M.check()
  local status = require("config.plugins").status().features.textobjects
  vim.health.start("Code textobjects")
  if not status.enabled then
    vim.health.ok("Extended textobjects are disabled")
    return
  elseif not status.active then
    vim.health.info("Install selected plugins and restart to enable extended textobjects")
    return
  end
  vim.health.ok("mini.ai is active; pattern-based objects are available")
  for _, record in ipairs(require("languages").selected()) do
    if record.parser then
      local ok, query = pcall(vim.treesitter.query.get, record.parser, "textobjects")
      if ok and query then
        vim.health.ok(record.parser .. " textobject queries are available")
      else
        vim.health.warn(record.parser .. " textobject queries are unavailable", {
          "Install the language parser with :TSInstallConfigured and provide textobject queries",
        })
      end
    end
  end
end

return M
