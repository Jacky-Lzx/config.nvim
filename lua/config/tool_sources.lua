-- Config-owned additions until they are available in toolchain-tools' registry.
local version = "18.7.0"
local assets = {}
for target, release in pairs({
  darwin_arm64 = { "mac-aarch64", "2255eadb7be3b58b93d17efcd6fb10809e40e2b28289fdb1af966a874dac13e4" },
  darwin_x64 = { "mac-x64", "90cf632a89604172b8170701bd04745dc73de4ac48d2eb4ced879bed532eaa4f" },
  linux_arm64_gnu = { "linux-aarch64", "3a92a4dd22ea87ff5d4de4891581ff41bacc7210256ebe9d0e496f1da8382f54" },
  linux_x64_gnu = { "linux-x64", "1e16df6c578dc76ff97d644445d126ba6fba5c2e8e174178ab86372652fd7612" },
}) do
  local filename = ("ltex-ls-plus-%s-%s.tar.gz"):format(version, release[1])
  assets[target] = {
    bin = { ["ltex-ls-plus"] = { path = "payload/ltex-ls-plus-" .. version .. "/bin/ltex-ls-plus" } },
    files = {
      {
        name = filename,
        url = "https://github.com/ltex-plus/ltex-ls-plus/releases/download/" .. version .. "/" .. filename,
        archive = "tar",
        sha256 = release[2],
      },
    },
  }
end

return {
  ["ltex-ls-plus"] = { kind = "download", version = version, assets = assets },
}
