local integration = require("languages.latex.lsp")
local settings = {
  build = { executable = "latexmk", onSave = true },
  diagnostics = {
    chktex = {
      enabled = true,
      arguments = {
        "-wall",
        "-n1",
        "-n3",
        "-n8",
        "-n9",
        "-n22",
        "-n30",
        "-n24",
        "-n17",
        "-n19",
        "-e16",
      },
    },
  },
}

return {
  cmd = { integration.executable() or "texquill", "--stdio" },
  filetypes = { "tex", "plaintex", "bib", "bst" },
  root_markers = { ".texquill.json", ".latexmkrc", "latexmkrc", ".texlabroot", ".git" },
  init_options = vim.deepcopy(settings),
  settings = { latex = vim.deepcopy(settings) },
  capabilities = { workspace = { diagnostic = { refreshSupport = true } } },
  handlers = {
    ["workspace/diagnostic/refresh"] = integration.refresh,
    ["latex/buildStarted"] = function() end,
    ["latex/buildFinished"] = function(err, result)
      if not err and result then
        local level = result.status == "success" and vim.log.levels.INFO or vim.log.levels.WARN
        vim.notify(result.message or ("Build: " .. result.status), level, { title = "texquill" })
      end
    end,
  },
  on_attach = integration.attach,
}
