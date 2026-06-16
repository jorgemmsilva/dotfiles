vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Per-project shada: keep jumplist/marks/registers from bleeding across
-- separate nvim instances. Must run before shada is read (startup step 15);
-- options.lua is required first in init.lua, so this is early enough.
do
  local cwd = vim.env.NV_HOST_DIR or vim.fn.getcwd()
  if vim.env.NVIM_EPHEMERAL then
    vim.o.shadafile = "NONE" -- match autosession's ephemeral behavior
  elseif cwd ~= "/" and cwd ~= vim.fn.expand "~/Downloads" then
    local enc = cwd:gsub("([/\\:*?\"'<>+ |%.%%])", function(c)
      return string.format("%%%02X", string.byte(c))
    end)
    local dir = vim.fn.stdpath "state" .. "/shada"
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
    vim.o.shadafile = dir .. "/proj-" .. enc .. ".shada"
  end
end

vim.opt.relativenumber = true

-- don't do backups, but let me keep undo's for days
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv "HOME" .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.scrolloff = 8 -- keep 8 lines, don't let the cursor hit the bottom of the page
-- vim.opt.sidescrolloff = 10 -- same as above, but for sides

vim.opt.wrap = false -- don't wrap lines

vim.o.cursorline = true --show cursorline
vim.o.cursorlineopt = "both"

vim.o.winborder = "rounded"

vim.o.laststatus = 3 -- statusline style (always show)
vim.o.showmode = false
vim.o.splitkeep = "screen"

-- Indenting
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.smartindent = true
vim.o.tabstop = 2
vim.o.softtabstop = 2

vim.opt.fillchars = { eob = " " } -- Characters to fill the statuslines, vertical separators, special lines in the window and truncated text
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.mouse = "a" -- mouse enabled for [a]ll modes
vim.o.mousemoveevent = true

-- Numbers
vim.o.number = true
vim.o.numberwidth = 2
-- vim.o.ruler = false

-- disable nvim intro
-- vim.opt.shortmess:append "sI"

vim.o.signcolumn = "yes"
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.timeoutlen = 400
vim.o.undofile = true

-- interval for writing swap file to disk, also used by gitsigns
vim.o.updatetime = 250

-- go to prev/next line with left/right when at the end/beginning of line
vim.opt.whichwrap:append "<>[]hl"

-- Use OSC 52 for clipboard so it works inside Docker/SSH with no display server
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy "+",
    ["*"] = require("vim.ui.clipboard.osc52").copy "*",
  },
  paste = {
    ["+"] = require("vim.ui.clipboard.osc52").paste "+",
    ["*"] = require("vim.ui.clipboard.osc52").paste "*",
  },
}

-- disable some default providers
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- add binaries installed by mason.nvim to path
-- local is_windows = vim.fn.has "win32" ~= 0
-- local sep = is_windows and "\\" or "/"
-- local delim = is_windows and ";" or ":"
-- vim.env.PATH = table.concat({ vim.fn.stdpath "data", "mason", "bin" }, sep) .. delim .. vim.env.PATH

vim.opt.title = true
vim.opt.titlelen = 0 -- do not shorten
vim.opt.titlestring = 'nvim %{expand("%:p")}'

vim.o.termguicolors = true
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- allow <C-o> to go to a closed buffer
-- vim.opt.jumpoptions:remove "clean"

-- new nvim features
--
vim.cmd "packadd nvim.undotree"

require("vim._core.ui2").enable {
  enable = true, -- Whether to enable or disable the UI.
  msg = {
    targets = "msg",
  },
}
