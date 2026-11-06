local M = {}
local handles = {}

-- Providers remain cold outside a selected vault; completion UI belongs to completion-tools.
function M.source()
  local provider
  local function current(ctx)
    local tools = package.loaded.obsidian_tools
    if tools and tools.workspace(vim.api.nvim_buf_get_name(ctx.bufnr)) then
      provider = provider or require("obsidian_tools.completion").new()
      return provider
    end
  end
  return {
    trigger = function(ctx)
      local source = current(ctx)
      return source ~= nil and source.trigger(ctx)
    end,
    complete = function(ctx, callback)
      local source = current(ctx)
      if source then
        return source.complete(ctx, callback)
      end
      callback({ items = {} })
    end,
  }
end

function M.setup(opts)
  local tools = require("obsidian_tools").setup(opts)
  local group = vim.api.nvim_create_augroup("ConfigObsidianTools", { clear = true })
  local function attach(buf)
    local id = "obsidian-tools.nvim." .. buf
    require("config.bindings").set(id, {})
    if handles[buf] then
      handles[buf]:dispose()
      handles[buf] = nil
    end
    if
      vim.bo[buf].buftype ~= ""
      or vim.bo[buf].filetype ~= "markdown"
      or not tools.workspace(vim.api.nvim_buf_get_name(buf))
    then
      return
    end
    handles[buf] = require("keymap_tools").register(id, {
      buf = buf,
      groups = { { prefix = "<leader>O", label = "Obsidian" } },
    })
    local entries = {}
    for _, entry in ipairs({
      { "O", "", "Commands" },
      { "D", "dailies", "Daily notes" },
      { "g", "search", "Search" },
      { "f", "quick_switch", "Quick switch" },
      { "q", "quick_switch", "Quick switch" },
      { "d", "follow_link", "Follow link" },
      { "b", "backlinks", "Backlinks" },
      { "t", "tags", "Tags" },
      { "n", "new", "New note" },
      { "N", "daily", "Today's daily note" },
      { "T", "template", "Insert template" },
      { "l", "link", "Insert note link" },
      { "r", "rename", "Rename/move note and update links" },
      { "R", "refresh", "Refresh index" },
    }) do
      entries[#entries + 1] = {
        "<leader>O" .. entry[1],
        "<Cmd>ObsidianTools " .. entry[2] .. "<CR>",
        buffer = buf,
        desc = "[Obsidian] " .. entry[3],
      }
    end
    entries[#entries + 1] = {
      "<leader>Op",
      function()
        require("image_tools.bootstrap").ensure().paste()
      end,
      buffer = buf,
      desc = "[Obsidian] Paste image",
    }
    require("config.bindings").set(id, entries)
  end
  vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
    group = group,
    callback = function(event)
      attach(event.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(event)
      require("config.bindings").set("obsidian-tools.nvim." .. event.buf, {})
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
