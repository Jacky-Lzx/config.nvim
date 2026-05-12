return {
  -- NOTE: The display effect does not look good. <2026.05.12, lzx>
  "sphamba/smear-cursor.nvim",
  opts = {
    -- Set to `true` if your font supports legacy computing symbols (block unicode symbols).
    -- Smears and particles will look a lot less blocky.
    legacy_computing_symbols_support = true,

    stiffness = 0.5,
    trailing_stiffness = 0.5,
    matrix_pixel_threshold = 0.5,
  },
}
