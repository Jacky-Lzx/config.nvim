local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.o.loadplugins = true
dofile(root .. "/tests/support/setup.lua")
dofile(root .. "/init.lua")
dofile(root .. "/tests/support/native_plugins.lua")

local count = 0
local function check()
  local plugins = require("config.plugins").nodes()
  assert(not plugins["nvim-treesitter"], "Main plugin must not be declared")
  assert(not vim.g.loaded_nvim_treesitter and not package.loaded["nvim-treesitter"])
  for _, path in ipairs(vim.opt.rtp:get()) do
    assert(not path:match("/nvim%-treesitter$") and not path:match("/nvim%-treesitter/"), path)
  end
  local parsers = require("toolchain.parsers")
  local util = require("toolchain.parser_util")
  local seen = {}
  for _, requirement in ipairs(require("integrations.toolchain").requirements("parser")) do
    local language = requirement.name
    if not seen[language] then
      seen[language] = true
      local info = parsers.info(language)
      assert(
        info.intact and info.receipt and info.receipt.parser,
        "Missing configured parser: " .. language .. "; run :ConfigToolsInstall explicitly"
      )
      count = count + 1
      assert(info.session == info.current, language)
      local library = vim.api.nvim_get_runtime_file("parser/" .. language .. ".so", false)[1]
      assert((vim.uv.fs_realpath(library) or library) == info.session .. "/parser/" .. language .. ".so", language)
      for relative in pairs(info.receipt.artifacts) do
        if relative:match("^queries/") then
          local path = info.current .. "/" .. relative
          local stat = vim.uv.fs_lstat(path)
          assert(stat and stat.type ~= "link" and util.read(path), path)
          local kind = relative:match("/([^/]+)%.scm$")
          if kind then
            for _, file in ipairs(vim.treesitter.query.get_files(language, kind)) do
              local resolved = vim.uv.fs_realpath(file) or file
              assert(not resolved:match("/plugin-tools/nvim%-treesitter/"), "Legacy query dependency: " .. resolved)
            end
            assert(vim.treesitter.query.get(language, kind), language .. "/" .. kind)
          end
        end
      end
      vim.treesitter.language.add(language)
    end
  end
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
  if seen.lua then
    assert(vim.treesitter.query.get("lua", "textobjects"))
  end
  assert(not package.loaded["nvim-treesitter"])
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
end

-- -l exits when the script returns, so wait for startup callbacks explicitly.
assert(
  vim.wait(3000, function()
    return vim.g.config_ready == true
  end),
  "ConfigReady was not reached"
)
local ok, err = xpcall(check, debug.traceback)
if not ok then
  io.stderr:write(err .. "\n")
  error(err, 0)
end
io.stdout:write(
  "Configured Tree-sitter runtime: " .. count .. " required libraries, aliases, predicates and textobjects passed\n"
)
