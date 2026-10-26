local integration = require("languages.latex.lsp")
local build = { executable = "latexmk", onSave = true }

return {
  cmd = { integration.executable() or "latex-lsp", "--stdio" },
  filetypes = { "tex", "plaintex", "bib", "bst" },
  root_markers = { ".latex-lsp.json", ".latexmkrc", "latexmkrc", ".texlabroot", ".git" },
  init_options = { build = vim.deepcopy(build) },
  settings = { latex = { build = vim.deepcopy(build) } },
  capabilities = { workspace = { diagnostic = { refreshSupport = true } } },
  handlers = {
    ["workspace/diagnostic/refresh"] = integration.refresh,
    ["latex/buildStarted"] = function() end,
    ["latex/buildFinished"] = function(err, result)
      if not err and result then
        local level = result.status == "success" and vim.log.levels.INFO or vim.log.levels.WARN
        vim.notify(result.message or ("Build: " .. result.status), level, { title = "latex-lsp" })
      end
    end,
  },
  on_attach = integration.attach,
}
