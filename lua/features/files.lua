-- Personal degradation flags and startup-frame orchestration.
local M = {}
local api = vim.api
local function guard()
  return require("config.plugin_bootstrap").library("bigfile-tools.nvim", "bigfile_tools")
end
function M.options()
  return {
    max_bytes = 1.5 * 1024 * 1024,
    max_line_length = 1000,
    buffer = { completion = false, ui_tools_disable = true, config_treesitter_disabled = true },
  }
end
function M.detect(buf, path)
  return guard().detect(buf, path)
end
function M.protect(buf)
  return guard().protect(buf)
end
function M.setup()
  guard().setup(M.options())
  api.nvim_create_autocmd("BufReadPost", {
    group = api.nvim_create_augroup("ConfigQuickfile", { clear = true }),
    once = true,
    nested = true,
    callback = function()
      M.quickfile()
    end,
  })
end

-- Registered before plugin loading, so startup file reads receive an early frame.
function M.quickfile()
  if vim.v.vim_did_enter == 1 or vim.fn.argc() == 0 or vim.bo.buftype ~= "" then
    return
  end
  local buf = api.nvim_get_current_buf()
  local file = api.nvim_buf_get_name(buf)
  if file == "" or not api.nvim_buf_is_loaded(buf) then
    return
  end
  if M.detect(buf, file) then
    M.protect(buf)
    return
  end
  local ft = vim.filetype.match({ buf = buf })
  if not ft then
    return
  end
  local lang = vim.treesitter.language.get_lang(ft)
  if lang == "latex" or not pcall(vim.treesitter.start, buf, lang) then
    vim.bo[buf].syntax = ft
  end
  vim.cmd.redraw()
end
return M
