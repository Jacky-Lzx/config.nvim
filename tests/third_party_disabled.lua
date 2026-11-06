-- Run through actual startup with the full personal selection and policy off.
local function check()
  assert(not require("config.third_party").enabled)
  local plugins = require("config.plugins")
  local manager, nodes = plugins.manager, plugins.nodes()
  local disabled = {
    "nvim-web-devicons",
    "conform.nvim",
    "nvim-lint",
    "vim-wakatime",
    "nvim-dap",
    "nvim-dap-view",
    "crates.nvim",
    "peek.nvim",
    "render-markdown.nvim",
    "obsidian.nvim",
    "typst-preview.nvim",
    "texpresso.vim",
    "codecompanion.nvim",
    "plenary.nvim",
  }
  for _, id in ipairs(disabled) do
    assert(not nodes[id], "Standalone third-party plugin is still active: " .. id)
  end
  assert(nodes["nvim-lspconfig"].parents["lsp-tools.nvim"])
  assert(nodes["lsp-tools.nvim"].dependencies["nvim-lspconfig"] == false)
  assert(manager.states["nvim-lspconfig"].phase == "mounted")
  for _, id in ipairs({
    "theme-tools.nvim",
    "completion-tools.nvim",
    "file-tools.nvim",
    "task-tools.nvim",
    "tex-tools.nvim",
  }) do
    assert(nodes[id], "Owned functionality disappeared: " .. id)
  end
  for _, command in ipairs({ "MarkdownPreview", "TypstPreview", "Obsidian", "DapContinue", "ConformInfo", "WakaTime" }) do
    assert(vim.fn.exists(":" .. command) == 0, "Disabled command survived: " .. command)
  end
  for _, key in ipairs({ "<leader>gf", "<leader>tf", "<leader>tm", "<F5>", "<leader>Du", "<leader>OO" }) do
    assert(vim.fn.maparg(key, "n") == "", "Disabled mapping survived: " .. key)
  end
  assert(not pcall(vim.api.nvim_get_autocmds, { group = "lzx_lint" }))
  local directory = vim.env.NVIM_TEST_TMP .. "/third-party-policy"
  vim.fn.mkdir(directory, "p")
  local files =
    { python = "sample.py", rust = "sample.rs", markdown = "sample.md", typst = "sample.typ", tex = "sample.tex" }
  for filetype, name in pairs(files) do
    vim.cmd.enew()
    vim.api.nvim_buf_set_name(0, directory .. "/" .. name)
    vim.bo.filetype = filetype
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "unchanged text" })
    vim.cmd.write()
    assert(not package.loaded.conform and not package.loaded.lint and not package.loaded.dap)
    assert(not package.loaded.crates and not package.loaded.peek and not package.loaded["render-markdown"])
    assert(not package.loaded["typst-preview"] and not package.loaded.obsidian)
  end
  assert(vim.lsp.config.lua_ls and vim.lsp.config.basedpyright, "Preserved provider no longer supplies configs")
  assert(require("theme_tools").current())
  assert(#require("theme_tools.icons").list() > 2, "Managed theme/icon providers were disabled")
  local snapshot = require("config").info()
  assert(snapshot.plugins.third_party == false)
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
  io.stdout:write(
    "Personal defaults passed: standalone third-party plugins disabled; LSP and managed themes/icons retained\n"
  )
end

local function run()
  local ok, err = xpcall(check, debug.traceback)
  if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
  end
  vim.cmd("qa!")
end
if vim.g.config_ready then
  vim.schedule(run)
else
  vim.api.nvim_create_autocmd("User", {
    pattern = "ConfigReady",
    once = true,
    callback = function()
      vim.schedule(run)
    end,
  })
end
