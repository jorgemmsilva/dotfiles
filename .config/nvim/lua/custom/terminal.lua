local M = {}

local floating_terminal = { win = -1, buf = -1 }

local PICK_CHARS = "ABCDEFGHIJKLMNOP"

-- Default predicate for windows that should never be a gf target:
-- floating windows, terminal buffers (incl. sidekick), and NvimTree.
local function default_exclude(win)
  local cfg = vim.api.nvim_win_get_config(win)
  if cfg.relative ~= "" then
    return true
  end
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype == "terminal" then
    return true
  end
  if vim.bo[buf].filetype == "NvimTree" then
    return true
  end
  return false
end

-- Pick a target window with an nvim-tree-style A/B/C overlay.
-- opts.exclude(win)   -> boolean to skip a window (defaults to default_exclude).
-- opts.empty_return   -> value returned when there are no candidates (default nil).
-- Returns a window id, opts.empty_return if none available, or nil if cancelled.
function M.pick_window(opts)
  opts = opts or {}
  local exclude = opts.exclude or default_exclude

  local candidates = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if not exclude(win) then
      candidates[#candidates + 1] = win
    end
  end

  if #candidates == 0 then
    return opts.empty_return
  end
  if #candidates == 1 then
    return candidates[1]
  end

  -- Overlay a floating label on each candidate window.
  local labels = {}
  local win_map = {}
  for i, win in ipairs(candidates) do
    local char = PICK_CHARS:sub(i, i)
    if char == "" then
      break
    end
    win_map[char] = win

    local w = vim.api.nvim_win_get_width(win)
    local h = vim.api.nvim_win_get_height(win)
    local lbuf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(lbuf, 0, -1, false, { "  " .. char .. "  " })
    local lwin = vim.api.nvim_open_win(lbuf, false, {
      relative = "win",
      win = win,
      width = 5,
      height = 1,
      row = math.max(0, math.floor(h / 2) - 1),
      col = math.max(0, math.floor(w / 2) - 2),
      style = "minimal",
      border = "rounded",
      focusable = false,
      noautocmd = true,
      zindex = 250,
    })
    vim.wo[lwin].winhl = "Normal:IncSearch,FloatBorder:IncSearch"
    labels[#labels + 1] = { win = lwin, buf = lbuf }
  end

  vim.cmd.redraw()

  local ok, ch = pcall(vim.fn.getcharstr)

  -- Clean up labels regardless of outcome.
  for _, l in ipairs(labels) do
    pcall(vim.api.nvim_win_close, l.win, true)
    pcall(vim.api.nvim_buf_delete, l.buf, { force = true })
  end

  if not ok then
    return nil
  end
  return win_map[ch:upper()]
end

-- Open the file under the cursor in a picked window instead of the terminal.
-- opts.src_win  : the terminal window the cursor is in
-- opts.hide_src : hide src_win after opening (used for floating terminals)
-- opts.exclude  : passed through to M.pick_window
function M.goto_file_under_cursor(opts)
  opts = opts or {}

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

  -- Hide the source terminal window only if requested (floating case).
  if opts.hide_src and opts.src_win and vim.api.nvim_win_is_valid(opts.src_win) then
    vim.api.nvim_win_hide(opts.src_win)
  end

  -- Pick the destination window (A/B/C overlay when multiple).
  local target_win = M.pick_window { exclude = opts.exclude }
  if not target_win or not vim.api.nvim_win_is_valid(target_win) then
    return
  end

  vim.api.nvim_set_current_win(target_win)

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
end

local function setup_terminal_keymap(buf, win, is_floating)
  -- Custom gf mapping: open file in a picked window instead of the terminal
  vim.keymap.set("n", "gf", function()
    M.goto_file_under_cursor { src_win = win, hide_src = is_floating }
  end, { buffer = buf, desc = "Go to file in picked window" })
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
