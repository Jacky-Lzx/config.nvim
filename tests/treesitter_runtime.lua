local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.o.loadplugins = true
dofile(root .. "/tests/setup.lua")
dofile(root .. "/init.lua")
dofile(root .. "/tests/native_plugins.lua")

local function check()
  local plugins = require("config.plugins").nodes()
  assert(not plugins["nvim-treesitter"], "Main plugin must not be declared")
  assert(not vim.g.loaded_nvim_treesitter and not package.loaded["nvim-treesitter"])
  for _, path in ipairs(vim.opt.rtp:get()) do
    assert(not path:match("/nvim%-treesitter$") and not path:match("/nvim%-treesitter/"), path)
  end
  local parsers = require("toolchain.parsers")
  local util = require("toolchain.parser_util")
  local lua = parsers.info("lua")
  local directory = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(lua.current)))
  local count = 0
  for filename in vim.fs.dir(directory .. "/current") do
    local language = filename:match("^([a-z][a-z0-9_]*)%.json$")
    if language then
      local info = parsers.info(language)
      if info.receipt and info.receipt.parser then
        count = count + 1
        assert(info.session == info.current, language)
        local library = vim.api.nvim_get_runtime_file("parser/" .. language .. ".so", false)[1]
        assert(library == info.session .. "/parser/" .. language .. ".so", library)
        for relative in pairs(info.receipt.artifacts) do
          if relative:match("^queries/") then
            assert(not vim.uv.fs_lstat(info.current .. "/" .. relative).type:match("link"))
            assert(util.read(info.current .. "/" .. relative))
            local kind = relative:match("/([^/]+)%.scm$")
            if kind then
              for _, file in ipairs(vim.treesitter.query.get_files(language, kind)) do
                local resolved = vim.uv.fs_realpath(file) or file
                assert(
                  not resolved:match("/plugin-tools/nvim%-treesitter/"),
                  "Legacy query dependency: " .. language .. "/" .. kind .. ": " .. resolved
                )
              end
              assert(vim.treesitter.query.get(language, kind), language .. "/" .. kind)
            end
          end
        end
        vim.treesitter.language.add(language)
      end
    end
  end
  assert(count >= 45, "Previously installed fallback languages must remain available")
  for filetype, language in pairs({
    tex = "latex",
    bib = "bibtex",
    sh = "bash",
    typescriptreact = "tsx",
    verilog = "systemverilog",
  }) do
    assert(vim.treesitter.language.get_lang(filetype) == language)
  end
  local predicates = vim.treesitter.query.list_predicates()
  assert(vim.list_contains(predicates, "kind-eq?") and vim.list_contains(predicates, "any-kind-eq?"))

  -- Editing uses managed parsers and its own bundled textobject queries.
  for _, id in ipairs({ "editing-tools.nvim" }) do
    require("plugin_tools").activate(id)
  end
  assert(require("config.plugins").initialized("editing-tools.nvim"))
  assert(not plugins["nvim-treesitter-textobjects"])
  assert(not package.loaded["mini.ai"])
  assert(vim.treesitter.query.get("lua", "textobjects"))
  if plugins["codecompanion.nvim"] then
    for _, id in ipairs({ "codecompanion.nvim" }) do
      require("plugin_tools").activate(id)
    end
    assert(require("config.plugins").initialized("codecompanion.nvim") and not plugins["nvim-treesitter"])
  end
  assert(not package.loaded["nvim-treesitter"])
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
end

-- -l exits when the script returns, so wait for startup callbacks explicitly.
vim.wait(100, function()
  return false
end, 10)
local ok, err = xpcall(check, debug.traceback)
if not ok then
  io.stderr:write(err .. "\n")
  error(err, 0)
end
io.stdout:write(
  "Independent Tree-sitter runtime: 45 libraries, aliases, predicates, textobjects and CodeCompanion passed\n"
)
