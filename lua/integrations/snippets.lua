local M = {}
local function load()
  if not package.loaded.snippet_tools then
    require("lazy").load({ plugins = { "snippet-tools.nvim" } })
  end
  return require("snippet_tools")
end
function M.engine()
  return "snippet-tools"
end
function M.active(direction)
  local s = package.loaded.snippet_tools
  return s and s.active(direction) or false
end
function M.jump(direction)
  local s = package.loaded.snippet_tools
  return s and s.jump(direction) or false
end
function M.choice(direction)
  local s = package.loaded.snippet_tools
  return s and s.change_choice(direction) or false
end
function M.select_choice()
  local s = package.loaded.snippet_tools
  return s and s.select_choice() or false
end
function M.capture()
  return load().cut_selection()
end
function M.expand(text, opts)
  return load().expand(text, {
    indent = not (opts and opts.insert_text_mode),
    expand_tabs = not opts or opts.insert_text_mode ~= 1,
    join_undo = true,
  })
end
function M.options()
  return { preset = "default", expand = M.expand, active = M.active, jump = M.jump }
end
function M.source()
  local source
  local function provider()
    if not source then
      load()
      source = require("snippet_tools.integrations.completion_tools").new()
    end
    return source
  end
  return {
    complete = function(ctx, callback)
      return provider().complete(ctx, function(result)
        local seen = {}
        result.items = vim.tbl_filter(function(item)
          if seen[item.label] then
            return false
          end
          seen[item.label] = true
          return true
        end, result.items)
        callback(result)
      end)
    end,
    resolve = function(entry, callback)
      return provider().resolve(entry, callback)
    end,
    execute = function(entry, ctx)
      return provider().execute(entry, ctx)
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
  })
  M.setup()
end
function M.setup()
  vim.keymap.set("x", "`", M.capture, { silent = true, desc = "Cut selection for snippet expansion" })
end
return M
