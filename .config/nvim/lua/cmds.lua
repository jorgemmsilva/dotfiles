-- use :Q to quit all
vim.cmd "command! Q q"
vim.cmd "command! QA qa"

-- open a vertical split and navigate back on the left window
vim.api.nvim_create_user_command("Vs", function()
  vim.cmd "vsplit"
  vim.cmd "wincmd h" -- Move to left window
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-o>", true, false, true), "n", false)
end, {})

-- open a horizontal split
vim.api.nvim_create_user_command("Hs", function()
  vim.cmd "split"
  vim.cmd "wincmd k" -- Move to upper window
end, {})

-- swap the current window with the next one (same as Ctrl+W x)
vim.cmd "command! Xs wincmd x"

-- colorize ansi text
vim.api.nvim_create_user_command("StripAnsi", function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for i, line in ipairs(lines) do
    lines[i] = line:gsub("\27%[[%d;]*m", "")
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end, {})

-- Terminal commands
local terminal = require "custom.terminal"

vim.api.nvim_create_user_command("TermNewH", function()
  terminal.open_split_terminal(false)
end, { desc = "Open new terminal in horizontal split" })

vim.api.nvim_create_user_command("TermNew", function()
  terminal.open_split_terminal(false)
end, { desc = "Open new terminal in horizontal split" })

vim.api.nvim_create_user_command("TermNewV", function()
  terminal.open_split_terminal(true)
end, { desc = "Open new terminal in vertical split" })

