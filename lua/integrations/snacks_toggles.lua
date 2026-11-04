local M = {}

-- Keep the exact switch object, rather than discovering it through map text.
-- Read the owner getter directly: Toggle:get() catches errors as false and
-- notifies, whereas keymap-tools represents read failures as unknown state.
function M.map(toggle, lhs, opts)
  opts = opts or {}
  local mode, buf = opts.mode or "n", opts.buffer or nil
  if buf == true or buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  toggle:map(lhs, vim.deepcopy(opts))
  return require("keymap_tools").register("snacks.toggle." .. toggle.opts.id .. ":" .. lhs, {
    buf = buf,
    modes = type(mode) == "table" and mode or { mode },
    toggles = {
      {
        keys = lhs,
        name = toggle.opts.name,
        get = function(ctx)
          if ctx.win then
            return vim.api.nvim_win_call(ctx.win, toggle.opts.get)
          end
        end,
      },
    },
  })
end

function M.setup(snacks)
  local map = M.map
  map(
    snacks.toggle.new({
      id = "Animation",
      name = "Animation",
      get = function()
        return snacks.animate.enabled()
      end,
      set = function(state)
        vim.g.snacks_animate = state
      end,
    }),
    "<leader>ta"
  )
  map(
    snacks.toggle.new({
      id = "scroll_anima",
      name = "Scroll animation",
      get = function()
        return snacks.scroll.enabled
      end,
      set = function(state)
        if state then
          snacks.scroll.enable()
        else
          snacks.scroll.disable()
        end
      end,
    }),
    "<leader>tS"
  )
  map(snacks.toggle.option("spell", { name = "Spelling" }), "<leader>ts")
  map(snacks.toggle.option("wrap", { name = "Wrap" }), "<leader>tw")
  map(snacks.toggle.option("relativenumber", { name = "Relative Number" }), "<leader>tL")
  map(snacks.toggle.line_number(), "<leader>tl")
  map(
    snacks.toggle.option("conceallevel", {
      off = 0,
      on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2,
    }),
    "<leader>tc"
  )
  map(snacks.toggle.treesitter(), "<leader>tT")
  map(snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }), "<leader>tb")
  map(
    snacks.toggle.inlay_hints({
      get = function()
        return vim.lsp.inlay_hint.is_enabled()
      end,
      set = function(state)
        vim.lsp.inlay_hint.enable(state)
      end,
    }),
    "<leader>th"
  )
  map(snacks.toggle.profiler(), "<leader>tPp")
  map(snacks.toggle.profiler_highlights(), "<leader>tPh")
  require("keymap_tools").register("snacks.profiler", {
    groups = { { prefix = "<leader>tP", label = "[profiler]" } },
  })
end

return M
