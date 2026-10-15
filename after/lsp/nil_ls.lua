return {
  settings = {
    ["nil"] = {
      formatting = { command = { "nixfmt" } },
      -- Load cached inputs without downloading them when a file is opened.
      nix = { flake = { autoArchive = false } },
    },
  },
}
