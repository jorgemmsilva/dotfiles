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
-- vim.g.auto_refresh_enabled = false
--
-- -- Function to toggle the behavior
-- function ToggleAutoRefresh()
--   if vim.g.auto_refresh_enabled then
--     vim.api.nvim_clear_autocmds { group = "AutoRefresh" }
--     vim.g.auto_refresh_enabled = false
--     print "Auto refresh disabled"
--   else
--     vim.o.autoread = true
--     vim.api.nvim_create_augroup("AutoRefresh", { clear = true })
--     vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
--       group = "AutoRefresh",
--       command = "if mode() != 'c' | checktime | endif",
--       pattern = "*",
--     })
--     vim.g.auto_refresh_enabled = true
--     print "Auto refresh enabled"
--   end
-- end
--
-- ToggleAutoRefresh() -- start with autorefresh enabled
--
-- vim.keymap.set("n", "<leader>rr", ToggleAutoRefresh, {
--   noremap = true,
--   silent = false,
--   desc = "Toggle auto refresh of files",
-- })

--------------
-- Set git branch for terminal buffers (so statusline shows it)
autocmd("TermOpen", {
  callback = function()
    local head = vim.trim(vim.fn.system "git rev-parse --abbrev-ref HEAD 2>/dev/null")
    if vim.v.shell_error == 0 then
      vim.b.gitsigns_head = head
    end
  end,
})

--------------
-- auto-suspend LSP after 15m of lost focus, restart on refocus
-- local lsp_suspend_timer = nil
-- local lsp_suspended = false
-- local LSP_TIMEOUT_MS = 15 * 60 * 1000
--
-- autocmd("FocusLost", {
--   callback = function()
--     if lsp_suspend_timer then
--       lsp_suspend_timer:stop()
--     end
--     lsp_suspend_timer = vim.defer_fn(function()
--       local clients = vim.lsp.get_clients()
--       if #clients > 0 then
--         for _, client in ipairs(clients) do
--           client:stop()
--         end
--         lsp_suspended = true
--       end
--       lsp_suspend_timer = nil
--     end, LSP_TIMEOUT_MS)
--   end,
-- })

-- autocmd("FocusGained", {
--   callback = function()
--     if lsp_suspend_timer then
--       lsp_suspend_timer:stop()
--       lsp_suspend_timer = nil
--     end
--     if lsp_suspended then
--       lsp_suspended = false
--       for _, win in ipairs(vim.api.nvim_list_wins()) do
--         local buf = vim.api.nvim_win_get_buf(win)
--         if vim.bo[buf].buftype == "" and vim.bo[buf].filetype ~= "" then
--           vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
--         end
--       end
--     end
--   end,
-- })

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
