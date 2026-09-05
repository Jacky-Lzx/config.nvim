-- Vue LSP (vtsls + vue_ls) shared setup
-- - Resolves the @vue/language-server package dir (Homebrew / npm -g / mason)
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
      local base = prefix .. "vue-language-server"
      local p = first_existing({ base .. "/node_modules/@vue/language-server", base })
      if p then
        return p
      end
    end
  end

  -- mason fallback
  return first_existing({
    vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/language-server",
  })
end

return M
