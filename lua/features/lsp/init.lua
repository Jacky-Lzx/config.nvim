local M = {}

function M.root(buffer, markers)
  if vim.bo[buffer].buftype ~= "" or vim.api.nvim_buf_get_name(buffer) == "" then
    return
  end
  for _, group in ipairs(markers) do
    local path = vim.fs.root(buffer, type(group) == "table" and group or { group })
    if path then
      return path
    end
  end
  return vim.fs.dirname(vim.api.nvim_buf_get_name(buffer))
end

function M.status()
  local enabled = require("config.settings").current().features.lsp
  local servers = {}
  if enabled then
    for _, record in ipairs(require("languages").selected()) do
      local executable = assert(vim.lsp.config[record.server], "Missing LSP configuration: " .. record.server).cmd[1]
      servers[#servers + 1] = {
        name = record.server,
        executable = executable,
        available = vim.fn.executable(executable) == 1,
        enabled = vim.lsp.is_enabled(record.server),
      }
    end
  end
  return { enabled = enabled, servers = servers }
end

function M.setup()
  if not require("config.settings").current().features.lsp then
    return
  end
  require("features.lsp.diagnostics").setup()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("ConfigLsp", { clear = true }),
    callback = function(event)
      require("features.lsp.keymaps").attach(event.buf)
    end,
  })
  vim.api.nvim_create_user_command("ConfigLspInfo", function()
    vim.print(M.status())
    local clients = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
      clients[#clients + 1] = { name = client.name, root = client.config.root_dir, id = client.id }
    end
    vim.print({ buffer_clients = clients })
  end, { force = true, desc = "Show selected language servers and buffer clients" })

  for _, record in ipairs(require("languages").selected()) do
    local definition = assert(vim.lsp.config[record.server], "Missing LSP configuration: " .. record.server)
    if vim.fn.executable(definition.cmd[1]) == 1 then
      local before_init = definition.before_init
      vim.lsp.config(record.server, {
        before_init = function(params, config)
          if require("config.plugins").status().started then
            require("lazy").load({ plugins = { "blink.cmp" } })
            config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
            params.capabilities = config.capabilities
          end
          if before_init then
            before_init(params, config)
          end
        end,
      })
      vim.lsp.enable(record.server)
    end
  end
end

return M
