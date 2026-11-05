local M = {}

-- Resolve the injected language using native Tree-sitter/filetype APIs.
function M.at_cursor()
  local parser = vim.treesitter.get_parser(0, nil, { error = false })
  if not parser then
    return vim.bo.commentstring
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  local range = { row, col, row, col + 1 }
  local result, depth = vim.bo.commentstring, 0
  local function visit(tree, level)
    if not tree:contains(range) then
      return
    end
    for _, filetype in ipairs(vim.treesitter.language.get_filetypes(tree:lang())) do
      local commentstring = vim.filetype.get_option(filetype, "commentstring")
      if type(commentstring) == "string" and commentstring ~= "" and level > depth then
        result, depth = commentstring, level
      end
    end
    for _, child in pairs(tree:children()) do
      visit(child, level + 1)
    end
  end
  visit(parser, 1)
  return result
end

return M
