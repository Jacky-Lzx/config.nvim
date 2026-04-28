vim.lsp.config("yamlls", {
  settings = {
    yaml = {
      format = {
        -- This seems not working. The formatter is still enabled.
        enable = false,
      },
      -- Associated a schema url, relative , or absolute (to root of project, not to filesystem root) path to the a glob
      -- pattern relative to the detected project root.
      schemas = {
        ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
      },
    },
  },
})

vim.lsp.enable("yamlls")
