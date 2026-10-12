local M = {}

local function has_env(name)
  return vim.env[name] ~= nil and vim.env[name] ~= ""
end

function M.setup()
  -- Select the provider before has('clipboard') initializes it. GUI clients
  -- and explicit user providers keep their own clipboard integration.
  if has_env("SSH_CONNECTION") and not vim.g.neovide and vim.g.clipboard == nil then
    vim.g.clipboard = "osc52"
  end
end

function M.on_yank(event)
  if event.operator ~= "y" or event.regname == "_" or #event.regcontents == 0 then
    return
  end

  -- Explicit + yanks already copied through the provider. Keep 'clipboard'
  -- empty so deletes and changes do not overwrite the system clipboard.
  if event.regname ~= "+" and vim.fn.has("clipboard") == 1 then
    pcall(vim.fn.setreg, "+", event.regcontents, event.regtype)
  end
end

return M
