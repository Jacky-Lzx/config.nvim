return {
  -- A plugin to take beautiful screenshots of your code
  {
    "mistricky/codesnap.nvim",
    build = "make",
    enabled = false,
    opts = {
      mac_window_bar = false,
      -- title = "CodeSnap.nvim",
      -- code_font_family = "CaskaydiaCove Nerd Font",
      -- watermark_font_family = "Pacifico",
      -- watermark = "CodeSnap.nvim",
      -- bg_theme = "default",
      breadcrumbs_separator = "/",
      has_breadcrumbs = false,
      has_line_number = true,
      show_workspace = false,
      min_width = 0,
      -- Hide background
      bg_padding = 0,
      save_path = os.getenv("XDG_DOWNLOAD_DIR") or (os.getenv("HOME") .. "/Downloads"),
    },
  },
}
