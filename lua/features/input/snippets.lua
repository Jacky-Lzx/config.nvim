local M = {}
local initialized = false

function M.options()
  local types = require("luasnip.util.types")

  return {
    link_roots = true,
    exit_roots = true,
    link_children = true,
    region_check_events = { "CursorMoved", "CursorHold", "InsertEnter" },
    delete_check_events = { "TextChanged", "InsertLeave" },
    cut_selection_keys = "`",
    enable_autosnippets = true,
    ext_opts = {
      [types.choiceNode] = {
        active = {
          virt_text = { { "", "BlinkCmpKindEnum" } },
          sign_text = "",
          sign_hl_group = "BlinkCmpKindEnum",
        },
        passive = { virt_text = { { "", "BlinkCmpLabel" } }, sign_text = "", sign_hl_group = "BlinkCmpLabel" },
      },
      [types.insertNode] = {
        active = {
          virt_text = { { "", "BlinkCmpKindText" } },
          sign_text = "",
          sign_hl_group = "BlinkCmpKindText",
        },
        passive = { virt_text = { { "", "BlinkCmpLabel" } }, sign_text = "", sign_hl_group = "BlinkCmpLabel" },
      },
    },
  }
end

function M.setup()
  if initialized then
    return
  end
  initialized = true

  local ls = require("luasnip")
  ls.setup(M.options())

  ls.filetype_extend("markdown", { "tex" })
  ls.filetype_extend("markdown_inline", { "markdown", "tex" })

  local path = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "snippets")
  if vim.fn.isdirectory(path) == 1 then
    require("luasnip.loaders.from_lua").lazy_load({ paths = { path } })
  end

  local snip_expand = ls.snip_expand
  ls.snip_expand = function(...)
    vim.o.undolevels = vim.o.undolevels
    return snip_expand(...)
  end

  vim.api.nvim_create_user_command("LuaSnipList", require("luasnip.extras.snippet_list").open, { force = true })
  vim.api.nvim_create_user_command("LuaSnipEdit", require("luasnip.loaders").edit_snippet_files, { force = true })

  for key, direction in pairs({ ["<A-j>"] = 1, ["<A-k>"] = -1 }) do
    vim.keymap.set({ "i", "s" }, key, function()
      if ls.choice_active() then
        ls.change_choice(direction)
      end
    end, { silent = true, desc = direction == 1 and "Next snippet choice" or "Previous snippet choice" })
  end
  vim.keymap.set({ "i", "s" }, "<A-c>", function()
    if ls.choice_active() then
      require("luasnip.extras.select_choice")()
    end
  end, { silent = true, desc = "Select snippet choice" })
end

return M
