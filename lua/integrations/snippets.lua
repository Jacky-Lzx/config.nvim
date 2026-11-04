local M = {}
local owners = {}
local markdown = { markdown = true, markdown_inline = true }

function M.engine(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  return vim.b[buf].snippet_engine or (markdown[vim.bo[buf].filetype] and "snippet-tools" or "luasnip")
end
function M.configure_legacy()
  local ls = package.loaded.luasnip
  if not ls then
    return
  end
  local native = M.engine() == "snippet-tools"
  ls.filetype_set("markdown", native and { "tex" } or { "markdown", "tex" })
  ls.filetype_set("markdown_inline", native and { "tex" } or { "markdown_inline", "markdown", "tex" })
end
local function legacy()
  local ls = require("luasnip")
  M.configure_legacy()
  return ls
end
local function order()
  if M.engine() ~= "snippet-tools" then
    return { "luasnip" }
  end
  return owners[vim.api.nvim_get_current_buf()] == "luasnip" and { "luasnip", "snippet-tools" }
    or { "snippet-tools", "luasnip" }
end
function M.active(direction)
  for _, engine in ipairs(order()) do
    if engine == "snippet-tools" then
      local s = package.loaded.snippet_tools
      if s and s.active(direction) then
        return true
      end
    elseif (direction == nil and legacy().in_snippet()) or (direction and legacy().locally_jumpable(direction)) then
      return true
    end
  end
  return false
end
function M.jump(direction)
  for _, engine in ipairs(order()) do
    if engine == "snippet-tools" then
      local s = package.loaded.snippet_tools
      if s and s.jump(direction) then
        return true
      end
    else
      local ls = legacy()
      if ls.locally_jumpable(direction) then
        ls.jump(direction)
        return true
      end
    end
  end
  return false
end
function M.choice(direction)
  for _, engine in ipairs(order()) do
    if engine == "snippet-tools" then
      local s = package.loaded.snippet_tools
      if s and s.change_choice(direction) then
        return true
      end
    else
      local ls = legacy()
      if ls.choice_active() then
        ls.change_choice(direction)
        return true
      end
    end
  end
  return false
end
function M.select_choice()
  for _, engine in ipairs(order()) do
    if engine == "snippet-tools" then
      local s = package.loaded.snippet_tools
      if s and s.select_choice() then
        return true
      end
    elseif legacy().choice_active() then
      require("luasnip.extras.select_choice")()
      return true
    end
  end
  return false
end
function M.capture()
  local ls = legacy()
  if M.engine() == "snippet-tools" then
    local text = require("snippet_tools").cut_selection()
    if type(text) == "string" then
      local lines = vim.split(text, "\n", { plain = true })
      vim.b.LUASNIP_SELECT_RAW, vim.b.LUASNIP_SELECT_DEDENT, vim.b.LUASNIP_TM_SELECT = lines, lines, lines
    end
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(ls.cut_keys, true, false, true), "in", false)
  end
end
function M.expand(text, opts)
  if M.engine() == "snippet-tools" then
    return require("snippet_tools").expand(text, {
      indent = not (opts and opts.insert_text_mode),
      expand_tabs = not opts or opts.insert_text_mode ~= 1,
      join_undo = true,
    })
  end
  legacy().lsp_expand(text, { indent = not (opts and opts.insert_text_mode) })
end
function M.options()
  return { preset = "default", expand = M.expand, active = M.active, jump = M.jump }
end
function M.source()
  local function providers()
    if not package.loaded.snippet_tools then
      require("lazy").load({ plugins = { "snippet-tools.nvim" } })
    end
    return require("snippet_tools.integrations.completion_tools").new(),
      require("completion_tools.sources.luasnip").new()
  end
  return {
    complete = function(ctx, callback)
      M.configure_legacy()
      local native, old = providers()
      if M.engine(ctx.bufnr) ~= "snippet-tools" then
        old.complete(ctx, callback)
        return
      end
      native.complete(ctx, function(result)
        local labels = {}
        for _, item in ipairs(result.items) do
          labels[item.label] = true
        end
        old.complete(ctx, function(fallback)
          for _, item in ipairs(fallback.items) do
            if not labels[item.label] then
              result.items[#result.items + 1] = item
            end
          end
          callback(result)
        end)
      end)
    end,
    resolve = function(entry, callback)
      local native, old = providers()
      return (entry.item._snippet_tools and native or old).resolve(entry, callback)
    end,
    execute = function(entry, ctx)
      local native, old = providers()
      owners[ctx.bufnr] = entry.item._snippet_tools and "snippet-tools" or "luasnip"
      if not entry.item._snippet_tools and package.loaded.snippet_tools then
        require("snippet_tools").clear_selection()
      end
      return (entry.item._snippet_tools and native or old).execute(entry, ctx)
    end,
  }
end
function M.setup_native()
  local s = require("snippet_tools")
  s.filetype_extend("markdown_inline", { "markdown" })
  s.setup({
    keymap = false,
    paths = { require("utils.paths").config("lua", "snippet_collections") },
    enabled = function(ctx)
      return M.engine(ctx.bufnr) == "snippet-tools"
    end,
  })
  M.setup()
end
function M.switch(value)
  assert(value == "auto" or value == "luasnip" or value == "snippet-tools", "Expected auto, luasnip or snippet-tools")
  require("lazy").load({ plugins = { "LuaSnip", "snippet-tools.nvim" } })
  local s, ls = require("snippet_tools"), legacy()
  s.stop()
  s.clear_selection()
  for _ = 1, 64 do
    if not ls.session.current_nodes[vim.api.nvim_get_current_buf()] then
      break
    end
    ls.unlink_current()
  end
  owners[vim.api.nvim_get_current_buf()] = nil
  vim.b.snippet_engine = value ~= "auto" and value or nil
  for _, key in ipairs({ "LUASNIP_SELECT_RAW", "LUASNIP_SELECT_DEDENT", "LUASNIP_TM_SELECT" }) do
    vim.b[key] = nil
  end
  M.configure_legacy()
  local cmp = package.loaded["completion_tools"]
  if cmp then
    cmp.hide()
  end
  vim.notify("Snippet engine: " .. M.engine() .. (value == "auto" and " (auto)" or ""))
end
function M.setup()
  local group = vim.api.nvim_create_augroup("ConfigSnippetEngines", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, { group = group, callback = M.configure_legacy })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(args)
      owners[args.buf] = nil
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "SnippetToolsEnter", "SnippetToolsExpand", "LuasnipInsertNodeEnter", "LuasnipChoiceNodeEnter" },
    callback = function(args)
      local native = args.match == "SnippetToolsEnter" or args.match == "SnippetToolsExpand"
      owners[vim.api.nvim_get_current_buf()] = native and "snippet-tools" or "luasnip"
      if native then
        for _, key in ipairs({ "LUASNIP_SELECT_RAW", "LUASNIP_SELECT_DEDENT", "LUASNIP_TM_SELECT" }) do
          vim.b[key] = nil
        end
      elseif package.loaded.snippet_tools then
        require("snippet_tools").clear_selection()
      end
    end,
  })
  vim.api.nvim_create_user_command("SnippetEngine", function(args)
    if args.args == "" then
      vim.notify("Snippet engine: " .. M.engine())
    else
      M.switch(args.args)
    end
  end, {
    nargs = "?",
    force = true,
    complete = function()
      return { "auto", "luasnip", "snippet-tools" }
    end,
  })
  vim.api.nvim_create_user_command("SnippetEngineToggle", function()
    M.switch(M.engine() == "snippet-tools" and "luasnip" or "snippet-tools")
  end, { force = true })
  vim.keymap.set("x", "`", M.capture, { silent = true, desc = "Cut selection for snippet expansion" })
end
return M
