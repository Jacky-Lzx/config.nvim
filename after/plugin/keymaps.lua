-- Map :W to :w
vim.api.nvim_create_user_command("W", "w", {})
-- Map :Wq to :wq
vim.api.nvim_create_user_command("Wq", "wq", {})
-- Bonus: Map :Q to :q
vim.api.nvim_create_user_command("Q", "q", {})

vim.keymap.del("n", "]a")
vim.keymap.del("n", "]A")
vim.keymap.del("n", "[a")
vim.keymap.del("n", "[A")

vim.keymap.set("i", "<C-h>", "<Left>")
vim.keymap.set("i", "<C-l>", "<Right>")
vim.keymap.set("i", "<C-j>", "<Down>")
vim.keymap.set("i", "<C-k>", "<Up>")

vim.keymap.set("i", "jk", "<Esc>")

vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-l>", "<C-w>l")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")

-- Defined at `nvim-hlslens`
-- vim.keymap.set({ "n", "v" }, "n", "nzz", { noremap = true, desc = "Next search" })
-- vim.keymap.set({ "n", "v" }, "N", "Nzz", { noremap = true, desc = "Previous search" })
-- vim.keymap.set("n", "<C-d>", "<C-d>zz")
-- vim.keymap.set("n", "<C-u>", "<C-u>zz")
-- vim.keymap.set("n", "//", "<CMD>:set hlsearch!<CR>")
-- vim.keymap.set("n", "//", "<CMD>:noh<CR>", { desc = "Clear search highlight" })

vim.keymap.set({ "n", "x", "o" }, "<S-H>", "^", { desc = "Start of line" })
vim.keymap.set({ "n", "x", "o" }, "<S-L>", "$", { desc = "End of line" })

vim.keymap.set({ "n", "x" }, "Q", "<CMD>:qa<CR>")
vim.keymap.set({ "n", "x" }, "qq", "<CMD>:q<CR>")
-- vim.keymap.set("n", "Q", "<CMD>:q<CR>")

vim.keymap.set("n", "<leader>J", "<CMD>cnext<CR>")
vim.keymap.set("n", "<leader>K", "<CMD>cprev<CR>")

vim.keymap.set("n", "<A-z>", "<CMD>set wrap!<CR>", { desc = "Toggle line wrap" })
vim.keymap.set("n", "<A-d>", "<NOP>", { desc = "Disabled" })

vim.keymap.set("v", "<M-m>", 'c\\( <c-r>" \\)')
vim.keymap.set("i", "<M-m>", "\\(  \\)<esc>hhi")

-- Add undo break-points
vim.keymap.set("i", ",", ",<c-g>u")
vim.keymap.set("i", ".", ".<c-g>u")
vim.keymap.set("i", ";", ";<c-g>u")

-- Better indenting (Re-select the texts after indentation)
vim.keymap.set("x", "<", "<gv")
vim.keymap.set("x", ">", ">gv")

-- 在命令行模式下，将 ":W" 映射为 ":w"
-- vim.keymap.set("c", "W", "w", { noremap = true, desc = "Map :W to :w (save file)" })

vim.api.nvim_create_user_command("ConvertTabToSpace", "%s/\t/  /g", {})

vim.keymap.set({ "i", "n" }, "<M-m>", function()
  local function on_files_selected(files)
    -- `files` is a list of absolute/normalized-ish paths (strings)
    -- Do whatever you want here:
    vim.notify("Selected:\n" .. table.concat(files, "\n"))
  end

  Snacks.picker.files({
    -- Override what happens when you press <CR> (confirm)
    actions = {
      confirm = function(picker, item)
        -- Get multi-selection (or current item if nothing is selected)
        local items = picker:selected({ fallback = true })

        -- Convert items -> file paths
        local files = vim.tbl_map(function(it)
          -- for the files picker items typically have it.file (and it.text)
          return it.file or it.text
        end, items)

        picker:close()

        -- Schedule if you’re going to open/edit files, etc.
        vim.schedule(function()
          on_files_selected(files)
        end)
      end,
    },
  })
end, { desc = "test" })

vim.keymap.set(
  { "n", "x" },
  "go",
  require("utils.utils").open_at_cursor,
  { desc = "Open link under cursor", nowait = true }
)

-- Function to pulse the cursor line
local function pulse_cursor()
  -- Set a highlight on the current line
  -- 'CursorLine' is a standard group, but you can use 'Visual' or 'Search' for more pop
  local match_id = vim.fn.matchadd("Visual", "\\%" .. vim.fn.line(".") .. "l")

  -- Clear the highlight after 200 milliseconds
  vim.defer_fn(function()
    vim.fn.matchdelete(match_id)
  end, 200)
end

-- Map double space to the function
-- <Space> is usually the leader, so we map it directly
vim.keymap.set("n", "<Space><Space>", pulse_cursor, { desc = "Pulse current line" })
