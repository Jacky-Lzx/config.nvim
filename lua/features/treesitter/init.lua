local M = {}

local function directory()
  return vim.fs.joinpath(vim.fn.stdpath("data"), "site")
end

function M.requirements()
  return { { "nvim-treesitter", "lua/nvim-treesitter/init.lua" } }
end

function M.status()
  local enabled = require("config.settings").current().features.treesitter
  local active = require("config.plugins").status().features.treesitter.active
  local parsers = {}
  if enabled then
    for _, record in ipairs(require("languages").selected()) do
      if record.parser then
        local path = vim.fs.joinpath(directory(), "parser", record.parser .. ".so")
        local revision_file = vim.fs.joinpath(directory(), "parser-info", record.parser .. ".revision")
        local revision = vim.fn.filereadable(revision_file) == 1 and vim.fn.readfile(revision_file)[1] or nil
        local expected = active and require("nvim-treesitter.parsers")[record.parser].install_info.revision or nil
        parsers[#parsers + 1] = {
          name = record.parser,
          language = record.language,
          path = path,
          revision = revision,
          expected_revision = expected,
          installed = vim.fn.filereadable(path) == 1 and vim.fn.filereadable(
            vim.fs.joinpath(directory(), "queries", record.parser, "highlights.scm")
          ) == 1 and revision ~= nil and revision == expected,
        }
      end
    end
  end
  return { enabled = enabled, active = active, install_dir = directory(), parsers = parsers }
end

function M.start(buf)
  if not require("config.plugins").status().features.treesitter.active then
    return
  end
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return
  end
  for _, record in ipairs(require("languages").selected()) do
    if record.parser and vim.list_contains(record.filetypes or {}, vim.bo[buf].filetype) then
      local highlighter = vim.treesitter.highlighter.active[buf]
      if highlighter and highlighter.tree:lang() == record.parser then
        return
      end
      local ok = pcall(vim.treesitter.start, buf, record.parser)
      if not ok then
        vim.treesitter.stop(buf)
        vim.bo[buf].syntax = vim.bo[buf].filetype
      end
      return
    end
  end
end

function M.start_loaded()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      M.start(buf)
    end
  end
end

function M.specs()
  return {
    {
      "nvim-treesitter/nvim-treesitter",
      lazy = vim.g.config_plugin_install and true or false,
      config = function()
        require("nvim-treesitter").setup({ install_dir = directory() })
      end,
    },
  }
end

function M.setup()
  vim.api.nvim_create_user_command("TSInstallConfigured", function()
    require("features.treesitter.install").run()
  end, { desc = "Install parsers for selected languages", force = true })
  local group = vim.api.nvim_create_augroup("ConfigTreesitter", { clear = true })
  if require("config.plugins").status().features.treesitter.active then
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      callback = function(event)
        M.start(event.buf)
      end,
    })
    M.start_loaded()
  end
end

return M
