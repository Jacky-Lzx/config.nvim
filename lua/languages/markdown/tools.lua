local M = {}
local filetypes = { "markdown" }
local handles = {}

function M.setup(opts)
  require("markdown_tools").setup(opts)
  local group = vim.api.nvim_create_augroup("ConfigMarkdownTools", { clear = true })
  local function attach(buf)
    local id = "markdown-tools.nvim." .. buf
    require("config.bindings").set(id, {})
    if handles[buf] then
      handles[buf]:dispose()
      handles[buf] = nil
    end
    if vim.bo[buf].buftype ~= "" or not vim.tbl_contains(filetypes, vim.bo[buf].filetype) then
      return
    end
    handles[buf] = require("keymap_tools").register(id, {
      buf = buf,
      groups = { { prefix = "<localleader>M", label = "Markdown" } },
    })
    local entries = {}
    for _, entry in ipairs({
      { "x", "ToggleCheckbox", "Toggle checkbox" },
      { "i", "InsertItem", "Insert list item" },
      { "n", "Renumber", "Renumber list" },
      { "o", "Outline", "Heading outline" },
      { "t", "Toc", "Insert/update table of contents" },
      { "h", "PromoteHeading", "Promote heading and children" },
      { "l", "DemoteHeading", "Demote heading and children" },
      { "]", "NextHeading", "Next heading" },
      { "[", "PreviousHeading", "Previous heading" },
      { "f", "FollowLink", "Follow link" },
      { "a", "FormatTable", "Align table" },
      { "j", "NextCell", "Next table cell" },
      { "k", "PreviousCell", "Previous table cell" },
      { "r", "InsertRow", "Insert table row" },
      { "R", "DeleteRow", "Delete table row" },
      { "c", "InsertColumn", "Insert table column" },
      { "C", "DeleteColumn", "Delete table column" },
      { "p", "Preview", "Preview Markdown" },
      { "e", "Export", "Export PDF" },
      { "?", "Info", "Markdown tools info" },
    }) do
      entries[#entries + 1] = {
        "<localleader>M" .. entry[1],
        "<Plug>(MarkdownTools" .. entry[2] .. ")",
        buffer = buf,
        desc = "[Markdown] " .. entry[3],
      }
    end
    entries[#entries + 1] = {
      "<localleader>Mx",
      ":<C-u>'<,'>MarkdownToolsToggleCheckbox<CR>",
      mode = "x",
      buffer = buf,
      desc = "[Markdown] Toggle selected checkboxes",
    }
    for key, action in pairs({
      ["]h"] = "NextHeading",
      ["[h"] = "PreviousHeading",
      ["]t"] = "NextCell",
      ["[t"] = "PreviousCell",
    }) do
      local exists = vim.api.nvim_buf_call(buf, function()
        return vim.fn.maparg(key, "n") ~= ""
      end)
      if not exists then
        entries[#entries + 1] = {
          key,
          "<Plug>(MarkdownTools" .. action .. ")",
          buffer = buf,
          desc = "[Markdown] " .. action,
        }
      end
    end
    require("config.bindings").set(id, entries)
  end
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(event)
      attach(event.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(event)
      require("config.bindings").set("markdown-tools.nvim." .. event.buf, {})
      if handles[event.buf] then
        handles[event.buf]:dispose()
        handles[event.buf] = nil
      end
    end,
  })
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    attach(buf)
  end
end

return M
