return {
  -- cmdline tools and lsp servers
  {
    "mason-org/mason.nvim",
    -- INFO: Mason should be started to inject the runtime path. It is loaded by nvim-lspconfig automatically. <2026.04.30, lzx>
    cmd = { "Mason", "MasonToolsInstall" },
    opts = {
      ensure_installed = {},
      post_install = {},
    },
    ---@param opts MasonSettings | {ensure_installed: string[]}
    config = function(_, opts)
      local setup_opts = vim.deepcopy(opts)
      setup_opts.ensure_installed = nil
      setup_opts.post_install = nil
      require("mason").setup(setup_opts)

      vim.api.nvim_create_user_command("MasonToolsInstall", function()
        local registry = require("mason-registry")
        local function install()
          local seen = {}
          for _, tool in ipairs(opts.ensure_installed) do
            if not seen[tool] then
              seen[tool] = true
              local package = registry.get_package(tool)
              local post_install = opts.post_install[tool]
              if package:is_installed() or vim.fn.executable(tool) == 1 then
                if package:is_installed() and post_install then
                  post_install(package)
                end
              else
                vim.notify("Installing " .. tool)
                if post_install then
                  package:once(
                    "install:success",
                    vim.schedule_wrap(function()
                      post_install(package)
                    end)
                  )
                end
                package:install()
              end
            end
          end
        end

        if registry.refresh then
          registry.refresh(install)
        else
          install()
        end
      end, { desc = "Install Mason tools for enabled language profiles", force = true })
    end,
  },
}
