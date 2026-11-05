local M = {}
local api = vim.api

-- Mark large/minified buffers before FileType consumers enable expensive work.
function M.detect(buf, path)
  path = path or api.nvim_buf_get_name(buf)
  local size = vim.fn.getfsize(path)
  local lines = api.nvim_buf_line_count(buf)
  return size > 1.5 * 1024 * 1024 or size > 0 and (size - lines) / math.max(1, lines) > 1000
end

function M.protect(buf)
  if vim.b[buf].bigfile then
    return
  end
  vim.b[buf].bigfile, vim.b[buf].completion = true, false
  vim.b[buf].ui_tools_disable, vim.b[buf].config_treesitter_disabled = true, true
  pcall(vim.treesitter.stop, buf)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.wo[win].foldmethod, vim.wo[win].foldexpr = "manual", "0"
    vim.wo[win].conceallevel, vim.wo[win].statuscolumn = 0, ""
  end
end

function M.setup()
  local group = api.nvim_create_augroup("ConfigBigfile", { clear = true })
  api.nvim_create_autocmd("BufReadPost", {
    group = group,
    once = true,
    nested = true,
    callback = function()
      M.quickfile()
    end,
  })
  vim.filetype.add({
    pattern = {
      [".*"] = {
        function(path, buf)
          if
            not buf
            or (vim.uv.fs_realpath(path) or vim.fs.normalize(path))
              ~= (vim.uv.fs_realpath(api.nvim_buf_get_name(buf)) or vim.fs.normalize(api.nvim_buf_get_name(buf)))
          then
            return
          end
          if M.detect(buf, path) then
            M.protect(buf)
            return "bigfile"
          end
        end,
        { priority = math.huge },
      },
    },
  })
  api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function(ev)
      if vim.b[ev.buf].bigfile then
        vim.wo.foldmethod, vim.wo.foldexpr, vim.wo.conceallevel, vim.wo.statuscolumn = "manual", "0", 0, ""
      end
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
