return {
  -- cmdline tools and lsp servers
  {
    "mason-org/mason.nvim",
    -- INFO: Mason should be started to inject the runtime path. It is loaded by nvim-lspconfig automatically. <2026.04.30, lzx>
    cmd = "Mason",
    opts = {
      ensure_installed = {},
    },
    ---@param opts MasonSettings | {ensure_installed: string[]}
    config = function(_, opts)
      require("mason").setup(opts)

      vim.schedule(function()
        local mr = require("mason-registry")
        local function ensure_installed()
          for _, tool in ipairs(opts.ensure_installed) do
            local p = mr.get_package(tool)
            if not p:is_installed() then
              p:install()
            end
          end
        end

        if mr.refresh then
          mr.refresh(ensure_installed)
        else
          ensure_installed()
        end
      end)
    end,
  },
}
