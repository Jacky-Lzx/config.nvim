return {
  servers = { "nil_ls" },
  tools = {
    { package = "nil", executable = "nil" },
    -- Use a system package for nixfmt.
    { executable = "nixfmt" },
    -- Optional: enables evaluation of flake inputs and NixOS options in nil.
    { executable = "nix" },
  },
  parsers = { "nix" },
  formatters = {
    nix = { "nixfmt" },
  },
}
