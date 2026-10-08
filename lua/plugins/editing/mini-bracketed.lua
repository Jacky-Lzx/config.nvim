return {
  {
    "echasnovski/mini.bracketed",
    version = "*",
    event = "VeryLazy",
      -- stylua: ignore
    keys = {
      { "]i",    function() require("mini.bracketed").indent("forward",  { change_type = "more" }) end, mode = { "n", "x", "o" }, desc = "Inner indent forward",      },
      { "[i",    function() require("mini.bracketed").indent("backward", { change_type = "more" }) end, mode = { "n", "x", "o" }, desc = "Inner indent backward",     },
      { "]o",    function() require("mini.bracketed").indent("forward",  { change_type = "less" }) end, mode = { "n", "x", "o" }, desc = "Outer indent forward",      },
      { "[o",    function() require("mini.bracketed").indent("backward", { change_type = "less" }) end, mode = { "n", "x", "o" }, desc = "Outer indent backward",     },
      { "<A-j>", function() require("mini.bracketed").diagnostic("forward")                        end, mode = { "n" },           desc = "Go to next diagnostic",     },
      { "<A-k>", function() require("mini.bracketed").diagnostic("backward")                       end, mode = { "n" },           desc = "Go to previous diagnostic", },
    },
    opts = {
      comment = { suffix = "" },
      conflict = { suffix = "" },
      file = { suffix = "" },
      indent = { suffix = "" },
      oldfile = { suffix = "" },
      undo = { suffix = "" },
      window = { suffix = "" },
      yank = { suffix = "" },
    },
  },
}
