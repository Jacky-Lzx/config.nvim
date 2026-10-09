local platform = require("utils.platform")

return {
  -- Use the SourceKit-LSP bundled with the selected Xcode toolchain on macOS.
  cmd = platform.is("macos") and { "xcrun", "sourcekit-lsp" } or { "sourcekit-lsp" },
}
