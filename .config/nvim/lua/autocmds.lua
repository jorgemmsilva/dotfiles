local autocmd = vim.api.nvim_create_autocmd

--------------
--- turn relative line numbers on / off for normal / insert mode
autocmd({ "InsertEnter" }, {
  pattern = "*",
  callback = function()
    vim.opt.relativenumber = false
  end,
})

autocmd({ "InsertLeave" }, {
  pattern = "*",
  callback = function()
    vim.opt.relativenumber = true
  end,
})

----------------
-- rename with F2
autocmd("LspAttach", {
  callback = function(args)
    vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, { buffer = args.buf, desc = "LSP Rename" })
  end,
})

---------------
---auto-refresh files when they change underneath

-- Create a variable to track the state
vim.g.auto_refresh_enabled = false

-- Function to toggle the behavior
function ToggleAutoRefresh()
  if vim.g.auto_refresh_enabled then
    vim.api.nvim_clear_autocmds { group = "AutoRefresh" }
    vim.g.auto_refresh_enabled = false
    print "Auto refresh disabled"
  else
    vim.o.autoread = true
    vim.api.nvim_create_augroup("AutoRefresh", { clear = true })
    vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
      group = "AutoRefresh",
      command = "if mode() != 'c' | checktime | endif",
      pattern = "*",
    })
    vim.g.auto_refresh_enabled = true
    print "Auto refresh enabled"
  end
end

ToggleAutoRefresh() -- start with autorefresh enabled

vim.keymap.set("n", "<leader>rr", ToggleAutoRefresh, {
  noremap = true,
  silent = false,
  desc = "Toggle auto refresh of files",
})

--------------
-- yankring
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    if vim.v.event.operator == "y" then
      for i = 9, 1, -1 do -- Shift all numbered registers.
        vim.fn.setreg(tostring(i), vim.fn.getreg(tostring(i - 1)))
      end
    end
  end,
})
