local M = {}

function M.engine(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  return vim.b[buf].snippet_engine or "snippet-tools"
end
function M.configure_legacy()
  local ls = package.loaded.luasnip
  if not ls then
    return
  end
  ls.filetype_set("tex", { "tex" })
  ls.filetype_set("markdown", { "markdown", "tex" })
  ls.filetype_set("markdown_inline", { "markdown_inline", "markdown", "tex" })
end
local function legacy()
  local ls = require("luasnip")
  M.configure_legacy()
  return ls
end
local function order()
  return { M.engine() }
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
  if M.engine() == "snippet-tools" then
    require("lazy").load({ plugins = { "snippet-tools.nvim" } })
    return require("snippet_tools").cut_selection()
  else
    local ls = legacy()
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
  local function provider(engine)
    if engine == "luasnip" then
      legacy()
      return require("completion_tools.sources.luasnip").new()
    end
    if not package.loaded.snippet_tools then
      require("lazy").load({ plugins = { "snippet-tools.nvim" } })
    end
    return require("snippet_tools.integrations.completion_tools").new()
  end
  return {
    complete = function(ctx, callback)
      local engine = M.engine(ctx.bufnr)
      local native = engine == "snippet-tools"
      return provider(engine).complete(ctx, function(result)
        if native then
          local seen = {}
          result.items = vim.tbl_filter(function(item)
            if seen[item.label] then
              return false
            end
            seen[item.label] = true
            return true
          end, result.items)
        end
        callback(result)
      end)
    end,
    resolve = function(entry, callback)
      return provider(entry.item._snippet_tools and "snippet-tools" or "luasnip").resolve(entry, callback)
    end,
    execute = function(entry, ctx)
      return provider(entry.item._snippet_tools and "snippet-tools" or "luasnip").execute(entry, ctx)
    end,
  }
end
function M.setup_native()
  local s = require("snippet_tools")
  local function decoration(icon, group)
    return {
      active = { virt_text = { { icon, group } }, sign_text = icon, sign_hl_group = group },
      passive = { virt_text = { { icon, "Comment" } }, sign_text = icon, sign_hl_group = "Comment" },
    }
  end
  s.filetype_extend("markdown", { "tex" })
  s.filetype_extend("markdown_inline", { "markdown" })
  s.filetype_extend("systemverilog", { "verilog" })
  s.setup({
    keymap = false,
    paths = { require("utils.paths").config("lua", "snippet_collections") },
    ext_opts = {
      insert = decoration("", "Identifier"),
      exit = decoration("", "Identifier"),
      choice = decoration("", "Type"),
    },
    enabled = function(ctx)
      return M.engine(ctx.bufnr) == "snippet-tools"
    end,
  })
  M.setup()
end
function M.switch(value)
  assert(value == "auto" or value == "luasnip" or value == "snippet-tools", "Expected auto, luasnip or snippet-tools")
  local destination = value == "luasnip" and "LuaSnip" or "snippet-tools.nvim"
  require("lazy").load({ plugins = { destination } })
  local s, ls = package.loaded.snippet_tools, package.loaded.luasnip
  if s then
    s.stop()
    s.clear_selection()
  end
  if ls then
    for _ = 1, 64 do
      if not ls.session.current_nodes[vim.api.nvim_get_current_buf()] then
        break
      end
      ls.unlink_current()
    end
  end
  vim.b.snippet_engine = value ~= "auto" and value or nil
  for _, key in ipairs({ "LUASNIP_SELECT_RAW", "LUASNIP_SELECT_DEDENT", "LUASNIP_TM_SELECT" }) do
    vim.b[key] = nil
  end
  M.configure_legacy()
  -- Routing can change after FileType; load the destination before its first query.
  if M.engine() == "luasnip" then
    require("luasnip.loaders").load_lazy_loaded(vim.api.nvim_get_current_buf())
  end
  local cmp = package.loaded["completion_tools"]
  if cmp then
    cmp.hide()
  end
  vim.notify("Snippet engine: " .. M.engine() .. (value == "auto" and " (auto)" or ""))
end
function M.setup()
  local group = vim.api.nvim_create_augroup("ConfigSnippetEngines", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, { group = group, callback = M.configure_legacy })
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
