local root = assert(vim.env.NVIM_CONFIG_ROOT, "NVIM_CONFIG_ROOT is required")
vim.opt.runtimepath:prepend(root)
vim.env.SSH_CONNECTION = nil
local before = #vim.api.nvim_get_autocmds({})
local clipboard = require("core.clipboard")
assert(vim.g.clipboard == nil and #vim.api.nvim_get_autocmds({}) == before)
clipboard.setup()
assert(vim.g.clipboard == nil, "Local sessions must keep clipboard auto-detection")
vim.env.SSH_CONNECTION = "test-client 1234 test-server 22"
clipboard.setup()
assert(vim.g.clipboard == "osc52", "SSH must select the native OSC 52 provider")
vim.g.clipboard = "custom-provider"
clipboard.setup()
assert(vim.g.clipboard == "custom-provider", "Explicit clipboard providers must win")
vim.g.clipboard, vim.g.neovide = nil, true
clipboard.setup()
assert(vim.g.clipboard == nil, "GUI clients must keep their own clipboard provider")
vim.g.neovide, vim.env.SSH_CONNECTION = nil, nil

local has, setreg = vim.fn.has, vim.fn.setreg
local copied = {}
local available = true
vim.fn.has = function(feature)
  if feature == "clipboard" then
    return available and 1 or 0
  end
  return has(feature)
end
vim.fn.setreg = function(register, lines, regtype)
  copied[#copied + 1] = { register = register, lines = vim.deepcopy(lines), regtype = regtype }
end
local event = { operator = "y", regname = "", regcontents = { "中文 'quotes'", "$(literal)" }, regtype = "V" }
clipboard.on_yank(event)
assert(#copied == 1)
assert(vim.deep_equal(copied[1], { register = "+", lines = event.regcontents, regtype = "V" }))
for _, operator in ipairs({ "d", "c" }) do
  clipboard.on_yank(vim.tbl_extend("force", event, { operator = operator }))
end
clipboard.on_yank(vim.tbl_extend("force", event, { regname = "_" }))
clipboard.on_yank(vim.tbl_extend("force", event, { regcontents = {} }))
clipboard.on_yank(vim.tbl_extend("force", event, { regname = "+" }))
assert(#copied == 1, "Deletes, changes, empty/black-hole yanks and explicit + must not copy again")
clipboard.on_yank(vim.tbl_extend("force", event, { regtype = "\22" .. "4", regname = "a" }))
assert(copied[#copied].regtype == "\22" .. "4", "Blockwise register type was lost")
available = false
local copy_count = #copied
clipboard.on_yank(event)
assert(#copied == copy_count, "Missing clipboard providers must skip copying")
available = true
vim.fn.setreg = function()
  error("clipboard provider failed")
end
assert(pcall(clipboard.on_yank, event), "Clipboard failure must not interrupt editing")
vim.fn.has, vim.fn.setreg = has, setreg

-- Exercise real yank events and the actual native OSC 52 provider. Capture the
-- terminal sequence so tests never overwrite the host's system clipboard.
vim.env.SSH_CONNECTION = "test-client 1234 test-server 22"
clipboard.setup()
vim.env.SSH_CONNECTION = nil
assert(vim.g.clipboard == "osc52")
vim.o.clipboard = ""
local ui_send = vim.api.nvim_ui_send
local sequences, highlights = {}, 0
vim.api.nvim_ui_send = function(sequence)
  sequences[#sequences + 1] = sequence
end
local on_yank = vim.hl.on_yank
vim.hl.on_yank = function()
  highlights = highlights + 1
end
local autocmds = require("core.autocmds")
autocmds.setup()
autocmds.setup()
local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), "xt", false)
end
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "中文 first", "second", "third" })
feed("ggyy")
assert(#sequences == 1 and highlights == 1, "Yank synchronization or highlighting ran twice")
assert(sequences[1] == "\27]52;c;" .. vim.base64.encode("中文 first\n") .. "\27\\")
feed("ddccchanged<Esc>")
assert(#sequences == 1, "Deletes and changes overwrote the clipboard")
feed('"ayy')
assert(#sequences == 2, "Named-register yanks must also copy to the system clipboard")
feed('"+yy')
assert(#sequences == 3, "Explicit + yanks must emit OSC 52 exactly once")
feed('"_yy')
assert(#sequences == 3, "Black-hole yanks must not copy")
assert(vim.o.clipboard == "")
vim.api.nvim_ui_send, vim.hl.on_yank = ui_send, on_yank
assert(not package.loaded["smartyank"])
print("Native clipboard selection, yank-only copying and OSC 52 encoding passed")
