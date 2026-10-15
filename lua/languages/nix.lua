return {
  servers = { "nil_ls" },
  tools = {
    { mason = "nil", executable = "nil" },
    -- Mason's nixfmt package only provides a Linux binary; use a system package.
    { executable = "nixfmt" },
    -- Optional: enables evaluation of flake inputs and NixOS options in nil.
    { executable = "nix" },
  },
  parsers = { "nix" },
  formatters = {
    nix = { "nixfmt" },
  },
}
