local M = {}

-- Blink owns Enter; returning nil keeps its normal newline fallback available.
function M.newline()
  if require("features.pairing").source().available then
    return require("pairs").expr("<CR>")
  end
end

return M
