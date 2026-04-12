require "options"

require "config.lazy"

require "filetypes"
require "autocmds"
require "cmds"
require "mappings"

-- custom plugins
require("custom.autosession").setup()
