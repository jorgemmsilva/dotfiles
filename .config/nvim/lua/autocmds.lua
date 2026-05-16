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
-- Multiple terminal fixes
--------------
-- Set git branch for terminal buffers (so statusline shows it)
-- fix yanking wrapped lines from the terminal
autocmd("TermOpen", {
  callback = function(ev)
    local head = vim.trim(vim.fn.system "git rev-parse --abbrev-ref HEAD 2>/dev/null")
    if vim.v.shell_error == 0 then
      vim.b.gitsigns_head = head
    end

    -- Smart yank: join soft-wrapped terminal lines before copying to system clipboard.
    -- Terminal soft-wrapped rows are always exactly the PTY width (padded with spaces).
    -- Lines shorter than the PTY width end with a real newline, so we keep those breaks.
    vim.keymap.set("v", "<leader>y", function()
      -- Get effective text area width (window width minus number col, signcolumn, etc.)
      local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
      local pty_width = wininfo.width - wininfo.textoff

      -- Get visual selection bounds (line and column)
      local v_start_line = vim.fn.line "v"
      local v_start_col = vim.fn.col "v"
      local v_end_line = vim.fn.line "."
      local v_end_col = vim.fn.col "."
      if v_start_line > v_end_line or (v_start_line == v_end_line and v_start_col > v_end_col) then
        v_start_line, v_end_line = v_end_line, v_start_line
        v_start_col, v_end_col = v_end_col, v_start_col
      end

      local lines = vim.api.nvim_buf_get_lines(0, v_start_line - 1, v_end_line, false)

      -- Trim to character-wise selection boundaries
      if #lines > 0 then
        lines[#lines] = string.sub(lines[#lines], 1, v_end_col)
        lines[1] = string.sub(lines[1], v_start_col)
      end

      -- Walk lines: join any line whose length >= pty_width with the next (it's a continuation)
      local result = {}
      local current = ""
      for _, line in ipairs(lines) do
        current = current .. line
        if #line < pty_width then
          table.insert(result, current)
          current = ""
        end
      end
      if current ~= "" then
        table.insert(result, current)
      end

      local text = table.concat(result, "\n")
      vim.fn.setreg("+", text)
      -- Exit visual mode
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
      vim.notify("Yanked " .. #result .. " logical line(s) to clipboard", vim.log.levels.INFO)
    end, { buffer = ev.buf, desc = "Smart yank: join wrapped terminal lines to system clipboard" })
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
