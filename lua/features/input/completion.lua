local M = {}

local function select(direction, options)
  return function(cmp)
    return cmp[direction](options)
  end
end

local function toggle_menu(cmp)
  if cmp.is_menu_visible() then
    return cmp.hide()
  end
  return cmp.show()
end

function M.sources()
  if not vim.b.blink_sources then
    vim.b.blink_sources = vim.deepcopy(require("blink.cmp.config").sources.default)
  end
  return vim.b.blink_sources
end

function M.code_sources()
  local sources = { "lsp", "path" }
  if require("blink.cmp.config").sources.providers.lazydev then
    table.insert(sources, 1, "lazydev")
  end
  return sources
end

function M.cycle(cmp, direction)
  local choices = { M.sources(), { "buffer" }, { "snippets" }, M.code_sources() }
  local index = vim.b.blink_cmp_provider_index or (direction == 1 and 1 or #choices + 1)
  index = (index - 1 + direction) % #choices + 1
  vim.b.blink_cmp_provider_index = index
  return cmp.show({ providers = choices[index] })
end

function M.toggle_source(cmp, name)
  local sources = M.sources()
  if vim.list_contains(sources, name) then
    sources = vim.tbl_filter(function(source)
      return source ~= name
    end, sources)
  else
    table.insert(sources, 1, name)
  end
  vim.b.blink_sources = sources
  return cmp.show({ providers = sources })
end

local function menu_direction()
  local cmp = require("blink.cmp")
  local context, item = cmp.get_context(), cmp.get_selected_item()
  if not context or not item then
    return { "s", "n" }
  end
  local text = item.textEdit and item.textEdit.newText or item.insertText or item.label
  if text:find("\n") or vim.g.blink_cmp_upwards_ctx_id == context.id then
    vim.g.blink_cmp_upwards_ctx_id = context.id
    return { "n", "s" }
  end
  return { "s", "n" }
end

local function navigation()
  return {
    ["<A-j>"] = { select("select_next", { auto_insert = false }), "fallback" },
    ["<A-k>"] = { select("select_prev", { auto_insert = false }), "fallback" },
    ["<C-n>"] = { select("select_next", { auto_insert = false }), "fallback" },
    ["<C-p>"] = { select("select_prev", { auto_insert = false }), "fallback" },
    ["<A-u>"] = { select("select_prev", { count = 5 }), "fallback" },
    ["<A-d>"] = { select("select_next", { count = 5 }), "fallback" },
    ["<Tab>"] = { "accept", "fallback" },
    ["<A-/>"] = { toggle_menu, "fallback" },
  }
end

function M.options()
  local keymap = navigation()
  keymap.preset = "default"
  keymap["<C-u>"] = { "scroll_documentation_up", "fallback" }
  keymap["<C-d>"] = { "scroll_documentation_down", "fallback" }
  keymap["<CR>"] = { "accept", require("features.input.pairing").newline, "fallback" }
  keymap["<S-CR>"] = {
    function(cmp)
      cmp.hide()
      return false
    end,
    "fallback",
  }
  keymap["<A-n>"] = {
    function(cmp)
      return M.cycle(cmp, 1)
    end,
  }
  keymap["<A-p>"] = {
    function(cmp)
      return M.cycle(cmp, -1)
    end,
  }

  local cmdline = navigation()
  cmdline.preset = "none"
  cmdline["<Up>"] = { select("select_prev", { auto_insert = false }), "fallback" }
  cmdline["<Down>"] = { select("select_next", { auto_insert = false }), "fallback" }
  cmdline["<CR>"] = { "fallback" }

  return {
    keymap = keymap,
    appearance = { nerd_font_variant = "normal" },
    completion = {
      accept = { auto_brackets = { enabled = true } },
      list = { selection = { preselect = true, auto_insert = false } },
      menu = { border = "rounded", max_height = 20, direction_priority = menu_direction },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
        window = {
          min_width = 10,
          max_width = 120,
          max_height = 20,
          border = "rounded",
          winblend = 0,
          winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",
          scrollbar = true,
          direction_priority = { menu_north = { "e", "w", "n", "s" }, menu_south = { "e", "w", "s", "n" } },
        },
      },
      ghost_text = {
        enabled = true,
        show_with_selection = true,
        show_without_selection = false,
        show_with_menu = true,
        show_without_menu = true,
      },
    },
    snippets = { preset = "luasnip" },
    sources = {
      default = { "lsp", "path", "buffer", "snippets" },
      providers = {
        path = {
          score_offset = 95,
          opts = {
            get_cwd = function()
              return vim.fn.getcwd()
            end,
          },
        },
        buffer = {
          score_offset = 20,
          opts = {
            get_bufnrs = function()
              return vim.tbl_filter(function(buffer)
                return vim.bo[buffer].buftype == ""
              end, vim.api.nvim_list_bufs())
            end,
          },
        },
        lsp = {
          score_offset = 60,
          fallbacks = { "buffer" },
          transform_items = function(_, items)
            local kind = require("blink.cmp.types").CompletionItemKind
            return vim.tbl_filter(function(item)
              return item.kind ~= kind.Text and item.kind ~= kind.Snippet
            end, items)
          end,
        },
        snippets = {
          score_offset = 100,
          should_show_items = function(context)
            return context.trigger.initial_kind ~= "trigger_character"
          end,
        },
        cmdline = {
          enabled = function()
            return vim.fn.getcmdtype() ~= ":" or not vim.fn.getcmdline():match("^[%%0-9,'<>%-]*!")
          end,
        },
      },
    },
    fuzzy = { implementation = "prefer_rust_with_warning", sorts = { "score", "kind", "label", "sort_text" } },
    signature = {
      enabled = false,
      window = {
        min_width = 1,
        max_width = 100,
        max_height = 10,
        border = "single",
        winblend = 0,
        winhighlight = "Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder",
        scrollbar = false,
        direction_priority = { "n" },
        treesitter_highlighting = true,
        show_documentation = true,
      },
    },
    cmdline = {
      enabled = true,
      keymap = cmdline,
      completion = {
        menu = { auto_show = true },
        list = { selection = { preselect = true, auto_insert = false } },
      },
    },
    term = { enabled = false },
  }
end

return M
