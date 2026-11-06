local M = {}

function M.executable()
  local path = vim.env.NVIM_TEXQUILL
  if path then
    return vim.fn.executable(path) == 1 and path or nil
  end
  return require("utils.platform").executable("texquill")
end

-- Neovim's workspace pull skips buffers already tracked by document diagnostics.
function M.refresh(err, result, ctx, config)
  local response = vim.lsp.handlers["workspace/diagnostic/refresh"](err, result, ctx, config)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  if not err and client and client:supports_method("workspace/diagnostic") then
    for bufnr in pairs(client.attached_buffers) do
      client:request("textDocument/diagnostic", {
        textDocument = { uri = vim.uri_from_bufnr(bufnr) },
        identifier = client.server_capabilities.diagnosticProvider.identifier,
      }, nil, bufnr)
    end
  end
  return response
end

function M.attach()
  require("integrations.bibtex_preview").setup()
end

return M
