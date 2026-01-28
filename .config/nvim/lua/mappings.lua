local map = vim.keymap.set

-- modes:
-- n -- Normal mode -- Regular mode when you’re navigating around
-- i -- Insert mode -- When you’re typing text
-- v -- Visual mode (charwise) -- When you visually select text (charwise)
-- x -- Visual mode (exclusive) -- Similar to v but behaves slightly differently internally
-- s -- Select mode -- Like visual, but behaves like insert
-- o -- Operator-pending mode -- While waiting for a movement after an operator (e.g., d, y)
-- ! -- Insert or command-line mode -- For mapping in insert or cmd-line mode
-- t -- Terminal mode -- In terminal buffers
-- c -- Command-line mode -- When typing commands after :

--------------------------------------------------------------------------------
--                          Navigation
--------------------------------------------------------------------------------

map("n", "gf", "gF", { desc = "open file under cursor (uses line and column if present" })

map("n", "<C-S-j>", "20j", { desc = "move down 20 lines" })
map("n", "<C-S-k>", "20k", { desc = "move up 20 lines" })
map("n", "<C-S-l>", "20zl", { desc = "scroll 20 chars to the right" })
map("n", "<C-S-h>", "20zh", { desc = "scroll 20 chars to the left" })

-- window navigation (in floating windows, act as j/k for menu navigation)
map("n", "<C-h>", "<C-w>h", { desc = "switch window left" })
map("n", "<C-l>", "<C-w>l", { desc = "switch window right" })
map("n", "<C-j>", function()
  if vim.api.nvim_win_get_config(0).relative ~= "" then
    return "j"
  end
  return "<C-w>j"
end, { expr = true, desc = "switch window down / menu down" })
map("n", "<C-k>", function()
  if vim.api.nvim_win_get_config(0).relative ~= "" then
    return "k"
  end
  return "<C-w>k"
end, { expr = true, desc = "switch window up / menu up" })

-- window resizing
-- map("n", "<C-Left>", "5<C-w><", { desc = "decrease window width" })
-- map("n", "<C-Right>", "5<C-w>>", { desc = "increase window width" })
-- map("n", "<C-S-<>", "3<C-w>-", { desc = "decrease window height" })
-- map("n", "<C-S->>", "3<C-w>+", { desc = "increase window height" })

-- keep cursor in the middle of the screen while scrolling
map("n", "<C-u>", "<C-u>zz")

-- prevent overscrolling at the bottom
vim.keymap.set("n", "<C-d>", function()
  local last_line = vim.fn.line "$"
  local bottom_visible = vim.fn.line "w$"
  if bottom_visible < last_line then
    -- keep cursor in the middle of the screen while scrolling
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-d>zz", true, false, true), "n", true)
  end
end, { noremap = true, silent = true, desc = "Smart <C-d>" })

-- keeps the cursor in the middle of the screen when searching
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- navigate "quick-fix list"
-- map("n", "<leader>j", "<cmd>cnext<CR>zz", { desc = "Quick-fix list next" })
-- map("n", "<leader>k", "<cmd>cprev<CR>zz", { desc = "Quick-fix list prev" })
map("n", "<F4>", "<cmd>cnext<CR>zz", { desc = "Quick-fix list next" })
map("n", "<S-F4>", "<cmd>cprev<CR>zz", { desc = "Quick-fix list next" })
map("n", "<F16>", "<cmd>cprev<CR>zz", { desc = "Quick-fix list prev" }) -- workaround for S-F4 not working in rio terminal

-- ADD J/K of 2+lines to jumplist
map("n", "j", [[v:count ? (v:count >= 3 ? "m'" . v:count : '') . 'j' : 'gj']], { noremap = true, expr = true })
map("n", "k", [[v:count ? (v:count >= 3 ? "m'" . v:count : '') . 'k' : 'gk']], { noremap = true, expr = true })

--- navigation with hjkl in insert mode
map("i", "<C-h>", "<ESC>^i", { desc = "move beginning of line" })
map("i", "<C-l>", "<End>", { desc = "move end of line" })
map("i", "<C-j>", "<Down>", { desc = "move down" })
map("i", "<C-k>", "<Up>", { desc = "move up" })

--------------------------------------------------------------------------------
--                          Neotest
--------------------------------------------------------------------------------
-- Tests
map("n", "<leader>tt", function()
  require("neotest").run.run()
end, { desc = "Run nearest test" })

map("n", "<leader>tf", function()
  require("neotest").run.run(vim.fn.expand "%")
end, { desc = "Run file tests" })

map("n", "<leader>ts", function()
  require("neotest").summary.toggle()
end, { desc = "Test summary" })

map("n", "<leader>to", function()
  require("neotest").output.open { enter = true }
end, { desc = "Test output" })

map("n", "<leader>td", function()
  ---@diagnostic disable-next-line: missing-fields
  require("neotest").run.run { strategy = "dap" }
end, { desc = "Debug nearest test" })

--------------------------------------------------------------------------------
--                          LSP integration
--------------------------------------------------------------------------------

--- code actions
-- NOTE: rio terminal has a custom binding to send custom escape code for <C-.>
-- vim.keymap.set({ "n", "v" }, "<F20>", function()
vim.keymap.set({ "n", "v" }, "<C-.>", function()
  if vim.bo.filetype == "rust" then
    vim.cmd.RustLsp "codeAction"
    return
  end

  local has_clients = next(vim.lsp.get_clients { bufnr = 0 }) ~= nil
  if not has_clients then
    vim.notify("No LSP client attached", vim.log.levels.WARN)
    return
  end

  vim.lsp.buf.code_action()
end, { silent = true, desc = "Show code actions" })

-- hover with ?
-- vim.keymap.set("n", "?", function()
--   -- TODO this should fall back to regular LSP hover when not in a rust file
--   vim.cmd.RustLsp { "hover", "actions" }
-- end, { silent = true, buffer = bufnr })

-- TODO:
-- RustLsp renderDiagnostics
-- vim.cmd.RustLsp('renderDiagnostic')
-- RustLsp explainError
-- vim.cmd.RustLsp('explainError')

--------------------------------------------------------------------------------
--                          Picker integration (snacks.nvim)
--------------------------------------------------------------------------------

-- snacks picker lsp integration
map("n", "gr", function()
  require("snacks").picker.lsp_references()
end, { noremap = true, desc = "[G]oto [R]eferences" })
map("n", "gi", function()
  require("snacks").picker.lsp_implementations()
end, { noremap = true, desc = "[G]oto [I]mplementation" })
map("n", "gd", function()
  require("snacks").picker.lsp_definitions()
end, { noremap = true, desc = "[G]oto [D]efinition" })
map("n", "go", function()
  require("snacks").picker.lsp_symbols()
end, { desc = "Open Document Symbols" })
map("n", "gW", function()
  require("snacks").picker.lsp_workspace_symbols()
end, { desc = "Open Workspace Symbols" })
map("n", "gt", function()
  require("snacks").picker.lsp_type_definitions()
end, { desc = "[G]oto [T]ype Definition}" })
map("n", "<leader>gl", function()
  require("snacks").picker.git_log()
end, { desc = "snacks git commits" })
-- This is not Goto Definition, this is Goto Declaration. (For example, in C this would take you to the header.)
map("n", "gD", vim.lsp.buf.declaration, { desc = "[G]oto [D]eclaration" })

map("n", "<C-e>", function()
  require("snacks").picker.files {
    hidden = true,
  }
end, { noremap = true, silent = true, desc = "snacks find files" })

map("n", "<C-f>", function()
  require("snacks").picker.grep {
    hidden = true,
  }
end, { noremap = true, silent = true, desc = "snacks live grep" })

-- Additional snacks picker commands (commented out for reference):
-- map("n", "<leader>fw", function() require("snacks").picker.grep() end, { desc = "snacks live grep" })
-- map("n", "<leader>fb", function() require("snacks").picker.buffers() end, { desc = "snacks find buffers" })
-- map("n", "<leader>fh", function() require("snacks").picker.help() end, { desc = "snacks help page" })
-- map("n", "<leader>fo", function() require("snacks").picker.recent() end, { desc = "snacks find recent files" })
-- map("n", "<leader>fz", function() require("snacks").picker.lines() end, { desc = "snacks find in current buffer" })
-- map("n", "<leader>gt", function() require("snacks").picker.git_status() end, { desc = "snacks git status" })
-- map("n", "<leader>ff", function() require("snacks").picker.files() end, { desc = "snacks find files" })
-- map("n", "<leader>fa", function() require("snacks").picker.files({ hidden = true }) end, { desc = "snacks find all files" })

--------------------------------------------------------------------------------
--                          GIT
--------------------------------------------------------------------------------
map("n", "gh", function()
  require("neogit").open() -- { kind = "split" }
end, { desc = "open neogit" })

map("n", "<leader>gs", function()
  require("snacks").picker.git_status()
end, { desc = "Git status" })
map("n", "<leader>gr", function()
  require("snacks").picker.git_branches()
end, { desc = "Git branches" })
map("n", "<leader>gc", function()
  require("snacks").picker.git_log_file()
end, { desc = "Git File History" })
map("n", "<leader>gC", ":DiffviewFileHistory %<CR>", { desc = "Git File History (Diffview)" })
map("n", "<leader>gg", function()
  require("snacks").gitbrowse()
end, { desc = "Open file in git URL" })
map("n", "<leader>gb", require("gitsigns").blame_line, { desc = "Git Blame Line" })
map("n", "<leader>gB", require("gitsigns").blame, { desc = "Git Blame" })

-- map("n", "<leader>gq", ":GitConflictListQf <CR>", { desc = "Git conflicts to quickfix" })
map("n", "<leader>gq", function()
  vim.cmd 'cexpr system("git diff --check --relative")'
  vim.cmd "copen"
end, { desc = "Git conflicts to quickfix" })

--------------------------------------------------------------------------------
--                          Visual selections
--------------------------------------------------------------------------------
-- shift+arrow selection
map("n", "<S-Up>", "v<Up>", { desc = "Select upward in normal mode" })
map("n", "<S-Down>", "v<Down>", { desc = "Select downward in normal mode" })
map("n", "<S-Left>", "v<Left>", { desc = "Select left in normal mode" })
map("n", "<S-Right>", "v<Right>", { desc = "Select right in normal mode" })

map("v", "<S-Up>", "<Up>", { desc = "Move selection upward" })
map("v", "<S-Down>", "<Down>", { desc = "Move selection downward" })
map("v", "<S-Left>", "<Left>", { desc = "Move selection left" })
map("v", "<S-Right>", "<Right>", { desc = "Move selection right" })

map("i", "<S-Up>", "<Esc>v<Up>", { desc = "Exit insert and select upward" })
map("i", "<S-Down>", "<Esc>v<Down>", { desc = "Exit insert and select downward" })
map("i", "<S-Left>", "<Esc>v<Left>", { desc = "Exit insert and select left" })
map("i", "<S-Right>", "<Esc>v<Right>", { desc = "Exit insert and select right" })

-- allow to move selected lines up/down
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

--------------------------------------------------------------------------------
--                           Clipboard
--------------------------------------------------------------------------------
--use leader to copy to system clipboard
vim.opt.clipboard = "" -- disables use of system clipboard
map("n", "<leader>y", '"+y', { desc = "copy to system clipboard" })
map("v", "<leader>y", '"+y', { desc = "copy to system clipboard" })
-- map({ "i", "!", "t", "c" }, "<C-p>", '<C-r>"', { desc = "Paste from clipboard in insert mode" })

-- paste from the yank register
map({ "n", "v", "x" }, "<leader>p", '"0p', { noremap = true, desc = "always paste from the yank register" })
map({ "n", "v", "x" }, "<leader>P", '"0P', { noremap = true, desc = "always paste from the yank register" })

--keep the contents of the _ register when pasting over a selection
-- map("x", "<leader-p>", "_dP")

-- put the `file/path:x:y` of the current visual selection into the system clipboard
map("v", "<leader>i", function()
  local start_line = vim.fn.line "v" -- start of current visual selection
  local end_line = vim.fn.line "." -- current cursor line
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local filepath = vim.fn.expand "%"
  local result = filepath .. ":" .. start_line .. ":" .. end_line
  vim.fn.setreg("+", result)
  print("Copied to clipboard: " .. result)
end, { desc = "Get file:line:line range" })

--------------------------------------------------------------------------------
--                          Buffers
--------------------------------------------------------------------------------
map("n", "<C-b>", function()
  require("snacks").picker.buffers()
end, { desc = "Open buffer picker" })

map("n", "<leader>b", "<cmd>enew<CR>", { desc = "buffer new" })
map("n", "<leader><S-x>", function()
  local visible_buffers = {}

  -- Get all buffers visible in windows
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    visible_buffers[buf] = true
  end

  local buffers_to_delete = {}

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if not visible_buffers[buf] and vim.bo[buf].buftype ~= "terminal" then
      table.insert(buffers_to_delete, buf)
    end
  end

  for _, buf in ipairs(buffers_to_delete) do
    vim.api.nvim_buf_delete(buf, { force = false })
  end
end, { desc = "close all buffers except those in windows" })

map("n", "<leader>x", function()
  Snacks.bufdelete()
end, { desc = "buffer close" })

-- Navigate buffers with Ctrl + PageDown/PageUp
map("n", "<C-PageDown>", ":bnext<CR>", { noremap = true, silent = true, desc = "Next buffer" })
map("n", "<C-PageUp>", ":bprevious<CR>", { noremap = true, silent = true, desc = "Previous buffer" })
map("n", "<leader>]", ":bnext<CR>", { desc = "buffer next" })
map("n", "<leader>[", ":bprevious<CR>", { desc = "buffer prev" })

--------------------------------------------------------------------------------
--                          Terminal
--------------------------------------------------------------------------------

-- this key combo no longer works
map({ "n", "t", "i" }, "<C-`>", (require "custom.terminal").toggle_floating_terminal, { desc = "Toggle terminal" })

-- map <Esc> to exit terminal mode
map("t", "<Esc>", [[<C-\><C-n>]], { noremap = true })

--------------------------------------------------------------------------------
--                          Pinned Files
--------------------------------------------------------------------------------

map("n", "<leader>=a", require("custom.pinned").add, { desc = "Pin current file" })
map("n", "=", require("custom.pinned").list, { desc = "List pinned files" })
map("n", "<leader>=r", require("custom.pinned").remove, { desc = "Remove pinned file" })
map("n", "<leader>=c", require("custom.pinned").clear, { desc = "Clear pinned files" })

--------------------------------------------------------------------------------
--                          MISC
--------------------------------------------------------------------------------

map("n", "<leader>u", "<cmd>UndotreeToggle<CR>")

map({ "n", "i" }, "<C-s>", "<Esc>:w<CR>", { desc = "save file" })
map({ "n", "i" }, "<C-S-s>", "<Esc>:wa<CR>", { desc = "Save all buffers" })

-- map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "general copy whole file" })

map({ "n", "x" }, "<leader>fm", function()
  require("conform").format { lsp_fallback = true }
end, { desc = "general format file" })

map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { noremap = true, silent = true, desc = "nvimtree toggle window" })

-- Comment
map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })

-- toggle line wrap
map("n", "<leader>z", function()
  ---@diagnostic disable-next-line: undefined-field
  vim.opt.wrap = not vim.opt.wrap:get()
end, { desc = "Toggle line wrap" })

-- use ESC to close floats
map("n", "<esc>", function()
  -- Close command-line window if open (q: or q/)
  if vim.fn.getcmdwintype() ~= "" then
    vim.cmd.quit()
    return
  end

  -- Collect floating windows first to avoid iterator invalidation
  local floating_wins = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative ~= "" then
      table.insert(floating_wins, win)
    end
  end

  -- Close them with pcall to handle errors gracefully
  for _, win in ipairs(floating_wins) do
    pcall(vim.api.nvim_win_close, win, false)
  end

  vim.cmd.nohlsearch() -- also clear search highlight
end)

-- replace occurances of the current word
map(
  "n",
  "<leader>s",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "replace all occurances current word" }
)

-- Toggle quickfix list
map("n", "<leader>q", function()
  local qf_exists = false
  for _, win in pairs(vim.fn.getwininfo()) do
    if win["quickfix"] == 1 then
      qf_exists = true
    end
  end
  if qf_exists == true then
    vim.cmd "cclose"
  else
    vim.cmd "botright copen"
  end
end, { desc = "Toggle quickfix" })

--------------------------------------------------------------------------------
--                          Debugger
--------------------------------------------------------------------------------

-- Toggle breakpoint
map("n", "<leader>db", function()
  require("dap").toggle_breakpoint()
end, { desc = "Debug: Toggle breakpoint" })

-- Set conditional breakpoint
map("n", "<leader>dB", function()
  require("dap").set_breakpoint(vim.fn.input "Breakpoint condition: ")
end, { desc = "Debug: Set conditional breakpoint" })

-- Set log point
map("n", "<leader>dl", function()
  require("dap").set_breakpoint(nil, nil, vim.fn.input "Log point message: ")
end, { desc = "Debug: Set log point" })

-- Start/Continue debugging
map("n", "<leader>dc", function()
  require("dap").continue()
end, { desc = "Debug: Start/Continue" })

-- Run last configuration
map("n", "<leader>dr", function()
  require("dap").run_last()
end, { desc = "Debug: Run last" })

-- Restart debugging session
map("n", "<leader>dR", function()
  require("dap").restart()
end, { desc = "Debug: Restart" })

-- Step over
map("n", "<leader>do", function()
  require("dap").step_over()
end, { desc = "Debug: Step over" })

-- Step into
map("n", "<leader>di", function()
  require("dap").step_into()
end, { desc = "Debug: Step into" })

-- Step out
map("n", "<leader>dO", function()
  require("dap").step_out()
end, { desc = "Debug: Step out" })

-- Terminate/Stop debugging
map("n", "<leader>dt", function()
  require("dap").terminate()
end, { desc = "Debug: Terminate" })

-- Pause debugging
map("n", "<leader>dp", function()
  require("dap").pause()
end, { desc = "Debug: Pause" })

-- Toggle DAP UI
map("n", "<leader>du", function()
  require("dapui").toggle()
end, { desc = "Debug: Toggle UI" })

-- Open DAP UI
map("n", "<leader>dU", function()
  require("dapui").open()
end, { desc = "Debug: Open UI" })

-- Close DAP UI
map("n", "<leader>dC", function()
  require("dapui").close()
end, { desc = "Debug: Close UI" })

-- Evaluate expression
map("n", "<leader>de", function()
  require("dap").eval()
end, { desc = "Debug: Evaluate expression" })

-- Evaluate expression (prompt)
map("n", "<leader>dE", function()
  require("dap").eval(vim.fn.input "Expression: ")
end, { desc = "Debug: Evaluate expression (prompt)" })

-- Run to cursor
map("n", "<leader>dg", function()
  require("dap").run_to_cursor()
end, { desc = "Debug: Run to cursor" })

-- Go to line (without executing)
map("n", "<leader>dj", function()
  require("dap").goto_()
end, { desc = "Debug: Go to line" })

-- Show hover information
map("n", "<leader>dh", function()
  require("dap.ui.widgets").hover()
end, { desc = "Debug: Hover" })

-- Preview variable
map("n", "<leader>dv", function()
  require("dap.ui.widgets").preview()
end, { desc = "Debug: Preview" })

-- Show frames
map("n", "<leader>df", function()
  local widgets = require "dap.ui.widgets"
  widgets.centered_float(widgets.frames)
end, { desc = "Debug: Frames" })

-- Show scopes
map("n", "<leader>ds", function()
  local widgets = require "dap.ui.widgets"
  widgets.centered_float(widgets.scopes)
end, { desc = "Debug: Scopes" })

-- Clear all breakpoints
map("n", "<leader>dx", function()
  require("dap").clear_breakpoints()
end, { desc = "Debug: Clear all breakpoints" })

-- List breakpoints
map("n", "<leader>dL", function()
  require("dap").list_breakpoints()
end, { desc = "Debug: List breakpoints" })
