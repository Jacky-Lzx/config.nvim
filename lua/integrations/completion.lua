local M = {}
M.source_config = {
  default = { "lsp", "path", "buffer", "snippets", "dictionary", "spell" },
  providers = { lsp = {}, path = {}, buffer = {}, snippets = {}, dictionary = {}, spell = {} },
}

function M.cycle(cmp, direction)
  local sources = require("features.completion").cycle(M.source_config, direction)
  cmp.hide()
  return cmp.show({ sources = sources })
end

function M.toggle_source(cmp, name)
  local sources = require("features.completion").toggle_source(M.source_config, name)
  cmp.hide()
  return cmp.show({ sources = sources })
end

function M.newline()
  return require("pairs").expr("<CR>")
end

function M.options()
  return {
    enabled = function()
      -- input-tools owns its native completefunc/popupmenu and confirmation.
      return vim.b.completion ~= false and vim.bo.filetype ~= "input-tools-input"
    end,
    sources = function()
      return require("features.completion").active_sources(M.source_config)
    end,
    providers = {
      lsp = {
        score_offset = 60,
        transform_items = function(_, items)
          return vim.tbl_filter(function(item)
            return item.kind ~= 1 and item.kind ~= 15
          end, items)
        end,
      },
      path = { score_offset = 95 },
      buffer = { score_offset = 20 },
      snippets = { score_offset = 60 },
      dictionary = { score_offset = 5 },
      spell = { score_offset = 10 },
    },
    path = {
      get_cwd = function()
        return vim.fn.getcwd()
      end,
    },
    buffer = {
      get_bufnrs = function()
        local current = vim.api.nvim_get_current_buf()
        return vim.tbl_filter(function(bufnr)
          return vim.api.nvim_buf_is_loaded(bufnr)
            and vim.bo[bufnr].buftype == ""
            and (bufnr == current or (vim.bo[current].filetype ~= "" and vim.bo[bufnr].filetype == vim.bo[current].filetype))
            and vim.api.nvim_buf_get_offset(bufnr, vim.api.nvim_buf_line_count(bufnr)) <= 1024 * 1024
        end, vim.api.nvim_list_bufs())
      end,
    },
    snippets = { preset = "luasnip" },
    dictionary = {
      files = { require("utils.paths").config("configs", "dictionary.txt") },
      min_keyword_length = 3,
      max_items = 10,
      matching = "fuzzy",
    },
    -- Native spell settings are inherited; active only in windows with 'spell'.
    spell = { sort = "match" },
    menu = {
      border = "rounded",
      max_height = 20,
      -- Match the previous Blink layout using completion-tools' own renderer.
      columns = { { "kind_icon" }, { "label", gap = 1 }, { "kind" } },
      kind_icons = true,
      label_details = true,
      highlight = { enabled = true, treesitter = true },
    },
    documentation = { auto_show = true, delay_ms = 200, max_width = 120, max_height = 20, border = "rounded" },
    cmdline = {
      enabled = true,
      get_anchor = function()
        local input = package.loaded["input-tools"]
        local box = input and input.get_layout()
        if box and not box.vim_mode then
          return { row = box.row, col = box.col, height = box.outer_height }
        end
      end,
      keymap = {
        ["<C-Space>"] = { "show", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<A-k>"] = { "select_prev", "fallback" },
        ["<A-j>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<A-u>"] = {
          function(cmp)
            return cmp.select_prev({ count = 5 })
          end,
          "fallback",
        },
        ["<A-d>"] = {
          function(cmp)
            return cmp.select_next({ count = 5 })
          end,
          "fallback",
        },
        ["<Tab>"] = { "accept", "show", "fallback" },
        ["<S-Tab>"] = { "select_prev", "show", "fallback" },
        ["<A-/>"] = {
          function(cmp)
            if cmp.is_menu_visible() then
              return cmp.hide()
            end
            return cmp.show()
          end,
          "fallback",
        },
        -- Enter retains the native command/search confirmation mapping.
      },
    },
    keymap = {
      ["<C-Space>"] = { "show", "show_documentation" },
      ["<A-k>"] = { "select_prev", "fallback" },
      ["<A-j>"] = { "select_next", "fallback" },
      ["<C-p>"] = { "select_prev", "fallback" },
      ["<C-n>"] = { "select_next", "fallback" },
      ["<A-u>"] = {
        function(cmp)
          return cmp.select_prev({ count = 5 })
        end,
        "fallback",
      },
      ["<A-d>"] = {
        function(cmp)
          return cmp.select_next({ count = 5 })
        end,
        "fallback",
      },
      ["<C-u>"] = { "scroll_documentation_up", "fallback" },
      ["<C-d>"] = { "scroll_documentation_down", "fallback" },
      ["<Tab>"] = { "accept", "fallback" },
      ["<CR>"] = { "accept", M.newline, "fallback" },
      ["<S-CR>"] = {
        function(cmp)
          cmp.hide()
          return "<CR>"
        end,
      },
      ["<A-/>"] = {
        function(cmp)
          if cmp.is_menu_visible() then
            return cmp.hide()
          end
          return cmp.show()
        end,
        "fallback",
      },
      ["<A-n>"] = {
        function(cmp)
          return M.cycle(cmp, 1)
        end,
      },
      ["<A-p>"] = {
        function(cmp)
          return M.cycle(cmp, -1)
        end,
      },
    },
  }
end

function M.setup()
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("ConfigCompletionLayout", { clear = true }),
    pattern = { "InputToolsOpen", "InputToolsLayoutChanged", "InputToolsClose" },
    callback = function()
      local cmp = package.loaded["completion-tools"]
      if cmp then
        cmp.refresh_cmdline()
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("ConfigCompletion", { clear = true }),
    pattern = "LazyLoad",
    callback = function(args)
      if args.data == "pairs.nvim" or args.data == "LuaSnip" then
        require("completion-tools").refresh_keymaps()
      end
    end,
  })
end

return M
