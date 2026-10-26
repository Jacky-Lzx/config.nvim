local M = {}

function M.executable()
  local platform = require("utils.platform")
  local default_path
  if platform.is("macos") then
    default_path = "~/Documents/Github/nvim_plugins/latex-lsp/target/release/texquill"
  elseif platform.is("linux") and vim.fn.filereadable("/etc/NIXOS") == 1 then
    default_path = "~/.local/share/t3-server/nix-data/projects/latex-lsp/target/release/texquill"
  end
  local path = vim.env.NVIM_TEXQUILL or (default_path and vim.fn.expand(default_path))
  if path and vim.fn.executable(path) == 1 then
    return path
  end
  return not vim.env.NVIM_TEXQUILL and platform.executable("texquill") or nil
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

function M.attach(client, bufnr)
  require("integrations.bibtex_preview").setup()
  require("languages.latex.linked_editing").attach(client, bufnr)

  local function request(command, arguments, callback)
    client:request("workspace/executeCommand", {
      command = "latex." .. command,
      arguments = arguments or { vim.uri_from_bufnr(bufnr) },
    }, function(err, result)
      if err then
        vim.notify(err.message, vim.log.levels.ERROR, { title = "texquill" })
      elseif callback then
        callback(result)
      end
    end, bufnr)
  end
  local function map(key, callback, description)
    vim.keymap.set("n", key, callback, { buffer = bufnr, desc = description })
  end
  local function build()
    local modified = vim.bo[bufnr].modified
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd.update()
    end)
    -- didSave already starts compilation when build on save is enabled.
    if not (modified and client.settings.latex.build.onSave) then
      request("build")
    end
  end
  map("<leader>lb", build, "Build with texquill")
  map("<localleader>ll", build, "Build with texquill")
  map("<localleader>lk", function()
    request("cancelBuild")
  end, "Cancel build")
  map("<localleader>lK", function()
    for _, server in ipairs(vim.lsp.get_clients({ name = "texquill" })) do
      server:exec_cmd({ command = "latex.cancelBuild", arguments = {} }, { bufnr = bufnr })
    end
  end, "Cancel all builds")
  map("<localleader>lg", function()
    request("buildStatus", nil, function(result)
      vim.notify(vim.inspect(result), vim.log.levels.INFO, { title = "texquill" })
    end)
  end, "Build status")
  map("<localleader>la", function()
    local settings = vim.deepcopy(client.settings)
    settings.latex.build.onSave = not settings.latex.build.onSave
    if client:notify("workspace/didChangeConfiguration", { settings = settings }) then
      client.settings = settings
      vim.notify("Build on save: " .. tostring(settings.latex.build.onSave), vim.log.levels.INFO)
    end
  end, "Toggle build on save")
  map("<localleader>le", function()
    vim.diagnostic.setqflist()
  end, "Errors and warnings")
  map("<localleader>lo", function()
    request("buildStatus", nil, function(result)
      vim.lsp.util.open_floating_preview(vim.split(result.output or "No build output", "\n"), "text", {})
    end)
  end, "Last compiler output")
  map("<localleader>lq", function()
    request("buildStatus", nil, function(result)
      if not result.logUri then
        vim.notify("Build the document first", vim.log.levels.WARN)
      else
        vim.cmd.split(vim.fn.fnameescape(vim.uri_to_fname(result.logUri)))
      end
    end)
  end, "Compiler log")
  map("<localleader>lV", "<Cmd>TexToolsView<CR>", "Open PDF")
  map("<localleader>lv", "<Cmd>TexToolsForwardSearch<CR>", "PDF forward search")
end

return M
