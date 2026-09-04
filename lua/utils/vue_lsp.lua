-- Vue LSP (vtsls + vue_ls) shared setup
-- - Resolves the @vue/language-server package dir (Homebrew / npm -g / mason)
-- - Pins bundled typescript back to 5.x when a broken 7.x is detected
-- - Enables vtsls + vue_ls (configs live in after/lsp/*.lua)
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

    -- last resort: ask npm for the global root
    local ok, root = pcall(vim.fn.systemlist, { "npm", "root", "-g" })
    if ok and root[1] and #root[1] > 0 then
      local p = first_existing({
        root[1] .. "/@vue/language-server",
        root[1] .. "/vue-language-server/node_modules/@vue/language-server",
        root[1] .. "/vue-language-server",
      })
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

--- If the resolved install bundles typescript 7.x (incompatible with
--- vue-language-server 3.3.x, crashes with
--- "TypeError: Cannot read properties of undefined (reading 'protocol')"),
--- pin it back to typescript@5 in place.
--- See: https://github.com/mason-org/mason.nvim/issues/2108
--- @return boolean true if a fix is currently running (LSP enable must wait)
local function ensure_typescript5(path)
  -- 修复进行中打开其他 vue 文件时也要等待
  if vim.g.__vue_ts_pin_pending == true then
    return true
  end
  if vim.g.__vue_ts_pin_checked then
    return false
  end
  vim.g.__vue_ts_pin_checked = true

  local f = io.open(path .. "/node_modules/typescript/package.json")
  if not f then
    return false
  end
  local json = f:read("*a")
  f:close()
  local v = json:match('"version"%s*:%s*"([%d%.]+)"')
  if not (v and v:match("^7%.")) then
    return false
  end

  vim.g.__vue_ts_pin_pending = true
  require("snacks.notify").warn(
    ("vue-language-server: 内置 typescript %s 不兼容，正在安装 typescript@5 ..."):format(v)
  )
  vim.system({ "npm", "install", "typescript@5", "--no-save", "--no-audit", "--no-fund" }, {
    cwd = path,
    on_exit = vim.schedule_wrap(function(_job, code)
      vim.g.__vue_ts_pin_pending = nil
      require("snacks.notify")[code == 0 and "ok" or "error"](
        code == 0 and "vue-language-server: 已钉住 typescript@5，请 :LspRestart 生效"
          or "vue-language-server: typescript@5 安装失败，请手动检查"
      )
    end),
  })
  return true
end

local started = false

--- Resolve path, pin TS if needed, then enable vtsls + vue_ls. Idempotent.
function M.setup()
  if started then
    return
  end
  started = true

  local path = M.server_path()
  if not path then
    require("snacks.notify").error(
      "vue-language-server 未找到（brew / npm -g / mason 均无），vue LSP 未启用"
    )
    return
  end

  local function enable()
    vim.lsp.enable({ "vtsls", "vue_ls" })
  end

  -- 如果正在钉 typescript@5，等安装完成后再 enable，避免 vue_ls 用 TS7 崩溃
  if ensure_typescript5(path) then
    local timer = vim.uv.new_timer()
    timer:start(
      1000,
      1000,
      vim.schedule_wrap(function()
        if vim.g.__vue_ts_pin_pending ~= true then
          timer:stop()
          timer:close()
          if #vim.lsp.get_clients({ name = "vue_ls" }) == 0 then
            enable()
          end
        end
      end)
    )
  else
    enable()
  end
end

return M
