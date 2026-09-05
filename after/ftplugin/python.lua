vim.opt_local.makeprg = vim.fn.fnameescape(require("config.platform").python()) .. " %"
