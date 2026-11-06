-- These must precede native TeX detection and ftplugins, even while tex-tools is cold.
if require("languages").is_enabled("latex") then
  vim.g.tex_flavor = "latex"
  vim.g.tex_conceal = ""
end

-- Keep zsh separate from sh so Bash formatters are not used for zsh syntax.
vim.filetype.add({
  extension = {
    zsh = "zsh",
  },
  filename = {
    [".zshrc"] = "zsh",
    [".zshenv"] = "zsh",
  },
})
