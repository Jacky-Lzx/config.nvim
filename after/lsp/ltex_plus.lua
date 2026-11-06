return {
  filetypes = { "markdown", "text", "tex", "plaintex" },
  settings = {
    ltex = {
      language = "en-US",
      checkFrequency = "save",
      additionalRules = { enablePickyRules = false },
      -- Keep spelling with typos-lsp, as it was with Harper.
      disabledRules = { ["en-US"] = { "MORFOLOGIK_RULE_EN_US" } },
    },
  },
}
