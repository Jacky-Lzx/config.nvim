return {
  {
    "kosayoda/nvim-lightbulb",
    event = "LspAttach",
    opts = {
      autocmd = { enabled = true },
      sign = {
        enabled = false,
        text = "",
      },
      virtual_text = {
        enabled = true,
        text = "",
      },
    },
  },
}
