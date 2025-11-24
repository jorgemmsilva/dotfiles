local M = {}

local floating_terminal = { win = -1, buf = -1 }

local function setup_terminal_keymap(buf, win, is_floating)
  -- Custom gf mapping: open file in background window instead of terminal
  vim.keymap.set("n", "gf", function()
    -- Get whole WORD (includes :, /, etc) and strip common prefixes/suffixes
    local cword = vim.fn.expand("<cWORD>"):gsub("^%s*%-?%-?>?%s*", ""):gsub("[,;\"'`)]$", "")
    if cword == "" then
      return
    end

    -- Parse file:line:col format
    local file, line, col = cword:match "^(.+):(%d+):(%d+)$"
    if not file then
      file, line = cword:match "^(.+):(%d+)$"
    end
    file = file or cword
    line = tonumber(line)
    col = tonumber(col)

    -- Switch to previously focused window
    vim.cmd "wincmd p"
    local target_win = vim.api.nvim_get_current_win()

    -- If we're still in the terminal (no other window), bail out
    if target_win == win then
      return
    end

    -- Hide terminal window only if it's floating
    if is_floating then
      vim.api.nvim_win_hide(win)
    end

    -- Position cursor after file loads (needed to override autocmds)
    if line then
      vim.api.nvim_create_autocmd("BufEnter", {
        once = true,
        callback = function()
          vim.schedule(function()
            pcall(vim.api.nvim_win_set_cursor, target_win, { line, col and (col - 1) or 0 })
            vim.cmd "normal! zz"
          end)
        end,
      })
    end

    vim.cmd("edit " .. vim.fn.fnameescape(file))
  end, { buffer = buf, desc = "Go to file in background window" })
end

local function make_floating_terminal(opts)
  opts = opts or {}
  local width = opts.width or math.floor(vim.o.columns * 0.8)
  local height = opts.height or math.floor(vim.o.lines * 0.8)
  local row = opts.row or math.floor((vim.o.lines - height) / 2)
  local col = opts.col or math.floor((vim.o.columns - width) / 2)

  local buf = nil
  local is_new_buf = false
  if vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
    is_new_buf = true
  end
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  -- make it a custom terminal only if it's a new buffer
  if is_new_buf then
    vim.cmd.terminal()
  end
  vim.cmd.startinsert()
  vim.wo[win].number = true
  vim.wo[win].relativenumber = true

  -- Setup custom gf mapping (floating = true)
  setup_terminal_keymap(buf, win, true)

  return { win = win, buf = buf }
end

M.toggle_floating_terminal = function()
  if floating_terminal.win == -1 or not vim.api.nvim_win_is_valid(floating_terminal.win) then
    floating_terminal = make_floating_terminal { buf = floating_terminal.buf }
  else
    vim.api.nvim_win_hide(floating_terminal.win)
  end
end

M.open_split_terminal = function(vertical)
  -- Create the split
  if vertical then
    vim.cmd "vsplit"
  else
    vim.cmd "split"
  end

  -- Create terminal in the new split
  vim.cmd.terminal()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()

  -- Apply same settings as floating terminal
  vim.wo[win].number = true
  vim.wo[win].relativenumber = true

  -- Setup custom gf mapping (floating = false, don't hide window)
  setup_terminal_keymap(buf, win, false)

  vim.cmd.startinsert()
end

return M
