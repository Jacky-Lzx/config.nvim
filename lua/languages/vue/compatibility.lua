-- Vue LSP (vtsls + vue_ls) shared setup
-- - Resolves the @vue/language-server package dir (Homebrew / npm -g / toolchain)
-- - Used by the vtsls and ts_ls configs in after/lsp/
-- Reference: https://github.com/vuejs/language-tools/wiki/Neovim

local M = {}

-- filetypes that should get the TS server (+ vue plugin)
M.filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" }

local function first_existing(paths)
  for _, p in ipairs(paths) do
    if vim.uv.fs_stat(p) then
      return p
    end
  end
  return nil
end

--- Resolve the @vue/language-server package directory.
--- @return string? path to the package dir (contains package.json + @vue/typescript-plugin), nil if not found
function M.server_path()
  local exe = vim.fn.exepath("vue-language-server")
  if exe ~= "" then
    local real = vim.fn.resolve(exe) -- global bins are usually symlinks

    -- Homebrew / scoped install:
    --   /opt/homebrew/Cellar/vue-language-server/x/libexec/lib/node_modules/@vue/language-server/bin/vue-language-server.js
    -- NOTE: `%-` 必须转义——Lua 5.5 中模式里的裸 `-` 是特殊字符 <2026.07, lzx>
    local scoped = real:match("^(.*)/@vue/language%-server/")
    if scoped then
      local p = scoped .. "/@vue/language-server"
      if vim.uv.fs_stat(p) then
        return p
      end
    end

    -- npm -g wrapper package: <root>/vue-language-server/bin/vue-language-server
    local prefix = real:match("^(.*)/vue%-language%-server/")
    if prefix then
      local base = prefix .. "/vue-language-server"
      local p = first_existing({ base .. "/node_modules/@vue/language-server", base })
      if p then
        return p
      end
    end
  end

  local tools = package.loaded["toolchain.tools"]
  return tools and tools.path("vue-language-server", "server") or nil
end

--- Pin an incompatible bundled TypeScript version during explicit tool installation.
function M.ensure_typescript5(package_path, done, log)
  local path = package_path .. "/node_modules/@vue/language-server"
  local package_json = path .. "/node_modules/typescript/package.json"
  local file = io.open(package_json)
  if not file then
    return done()
  end

  local version = file:read("*a"):match('"version"%s*:%s*"([%d%.]+)"')
  file:close()
  if not (version and version:match("^7%.")) then
    return done()
  end

  vim.notify(("vue-language-server: replacing incompatible TypeScript %s with TypeScript 5"):format(version))
  vim.system({ "npm", "install", "typescript@5", "--no-save", "--no-audit", "--no-fund" }, {
    cwd = path,
    text = true,
  }, function(result)
    vim.schedule(function()
      log(result.stdout or "")
      log(result.stderr or "")
      if result.code == 0 then
        vim.notify("vue-language-server: TypeScript 5 installed; restart Vue LSP clients")
        done()
      else
        done("vue-language-server: TypeScript 5 repair failed (exit " .. result.code .. ")")
      end
    end)
  end)
end

return M
