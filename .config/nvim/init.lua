-- Make sure to setup options like `mapleader` and `maplocalleader` before loading lazy
require "options"

require "config.lazy"

require "filetypes"
require "autocmds"
require "cmds"

-- vim.schedule(function()
require "mappings"
-- end)

-- TODO uncomment once v0.12 is out
-- vim.cmd "packadd nvim.undotree"
