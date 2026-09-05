vim.lsp.config("*", { capabilities = vim.lsp.protocol.make_client_capabilities() })

-- Use LspAttach autocommand to only map the following keys after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
    end

    map("<leader>d", vim.diagnostic.open_float, "[LSP] Show diagnostic")
    map("<leader>gk", vim.lsp.buf.signature_help, "[LSP] Signature help")
    -- vim.keymap.set("n", "<leader>sK", vim.lsp.buf.signature_help, { desc = "[LSP] Signature help" })
    map("<leader>gf", vim.lsp.buf.format, "[LSP] Format")
    map("<leader>rn", vim.lsp.buf.rename, "[LSP] Rename")

    map("<leader>gr", vim.lsp.buf.references, "[LSP] References")
    map("<leader>gt", vim.lsp.buf.type_definition, "[LSP] Type definition")

    map("<leader>wa", vim.lsp.buf.add_workspace_folder, "[LSP] Add workspace folder")
    map("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[LSP] Remove workspace folder")
    map("<leader>wl", function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, "[LSP] List workspace folders")
    -- vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts_local)
  end,
})

vim.schedule(function()
  vim.lsp.enable("copilot")
  vim.lsp.enable("typos_lsp")

  local signs = { Error = "", Warn = "", Hint = "󰌶", Info = "" }
  for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
  end

  local virtual_text_config_enabled = {
    spacing = 4,
    prefix = function(diagnostic)
      if diagnostic.severity == vim.diagnostic.severity.ERROR then
        return signs.Error
      elseif diagnostic.severity == vim.diagnostic.severity.WARN then
        return signs.Warn
      elseif diagnostic.severity == vim.diagnostic.severity.INFO then
        return signs.Info
      elseif diagnostic.severity == vim.diagnostic.severity.HINT then
        return signs.Hint
      end
      return diagnostic.message
    end,
  }

  local virtual_text_config_disabled = {
    spacing = 0,
    format = function(_)
      return ""
    end,
    prefix = function(diagnostic)
      if diagnostic.severity == vim.diagnostic.severity.ERROR then
        return signs.Error
      elseif diagnostic.severity == vim.diagnostic.severity.WARN then
        return signs.Warn
      elseif diagnostic.severity == vim.diagnostic.severity.INFO then
        return signs.Info
      elseif diagnostic.severity == vim.diagnostic.severity.HINT then
        return signs.Hint
      end
      return diagnostic.message
    end,
  }

  local signs_config = {
    text = {
      [vim.diagnostic.severity.ERROR] = signs.Error,
      [vim.diagnostic.severity.WARN] = signs.Warn,
      [vim.diagnostic.severity.INFO] = signs.Info,
      [vim.diagnostic.severity.HINT] = signs.Hint,
    },
    severity = {
      vim.diagnostic.severity.ERROR,
      vim.diagnostic.severity.WARN,
      vim.diagnostic.severity.INFO,
      vim.diagnostic.severity.HINT,
    },
  }

  local virtual_lines_config = { current_line = true }
  vim.diagnostic.config({
    underline = false,
    signs = signs_config,
    update_in_insert = false,
    virtual_text = virtual_text_config_enabled,
    virtual_lines = false,
    severity_sort = true,
    float = {
      border = "rounded",
    },
  })

  local snacks = require("snacks")

  snacks.toggle.diagnostics():map("<leader>td")
  snacks.toggle
    .new({
      id = "virtual_lines",
      name = "Virtual lines",
      get = function()
        return not not vim.diagnostic.config().virtual_lines
      end,
      set = function(state)
        if state then
          vim.diagnostic.config({ virtual_lines = virtual_lines_config })
        else
          vim.diagnostic.config({ virtual_lines = false })
        end
      end,
    })
    :map("<leader>tV")
  snacks.toggle
    .new({
      id = "virtual_text",
      name = "Virtual text",
      get = function()
        return vim.diagnostic.config().virtual_text.format == virtual_text_config_enabled.format
      end,
      set = function(state)
        if state then
          vim.diagnostic.config({ virtual_text = virtual_text_config_enabled })
        else
          vim.diagnostic.config({ virtual_text = virtual_text_config_disabled })
        end
      end,
    })
    :map("<leader>tv")
end)
