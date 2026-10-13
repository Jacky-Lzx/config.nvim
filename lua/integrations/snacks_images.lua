local M = {}

function M.preview(ctx)
  local ok, image = pcall(require, "image_tools")
  if ok then
    return image.snacks_preview(ctx)
  end
  return Snacks.picker.preview.file(ctx)
end

return M
