local M = {}

-- Percent encode a path (same as auto-session does)
local function percent_encode(str)
  if str == nil then
    return ""
  end
  -- Encode path separators and special characters
  return (str:gsub("([/\\:*?\"'<>+ |%.%%])", function(c)
    return string.format("%%%02X", string.byte(c))
  end))
end

-- Get the pinned file for the current directory
local function get_pinned_file()
  local pinned_dir = vim.fn.stdpath "data" .. "/pinned"

  -- Create pinned directory if it doesn't exist
  if vim.fn.isdirectory(pinned_dir) == 0 then
    vim.fn.mkdir(pinned_dir, "p")
  end

  -- Use current working directory as the key
  local cwd = vim.fn.getcwd()
  -- Create a safe filename from the path (same format as sessions)
  local filename = percent_encode(cwd)
  return pinned_dir .. "/" .. filename
end

-- Add current file to list
function M.add()
  local filepath = vim.fn.expand "%:p"
  if filepath == "" then
    return
  end

  local pinned_file = get_pinned_file()
  local lines = vim.fn.filereadable(pinned_file) == 1 and vim.fn.readfile(pinned_file) or {}

  if not vim.tbl_contains(lines, filepath) then
    table.insert(lines, filepath)
    vim.fn.writefile(lines, pinned_file)
    print("Pinned: " .. filepath)
  end
end

-- List and select file using snacks picker
function M.list()
  local pinned_file = get_pinned_file()

  if vim.fn.filereadable(pinned_file) == 0 then
    print "No pinned files"
    return
  end

  local lines = vim.fn.readfile(pinned_file)
  if #lines == 0 then
    print "No pinned files"
    return
  end

  local items = {}
  for i, path in ipairs(lines) do
    table.insert(items, {
      idx = i,
      file = path,
      text = path,
    })
  end

  local Snacks = require "snacks"
  Snacks.picker.pick {
    items = items,
    format = "file",
    preview = "file",
    confirm = function(picker, item)
      picker:close()
      vim.cmd("edit " .. vim.fn.fnameescape(item.file))
    end,
    actions = {
      delete = function(picker, item)
        local pf = get_pinned_file()
        local current_lines = vim.fn.readfile(pf)
        local new_lines = {}
        for _, path in ipairs(current_lines) do
          if path ~= item.file then
            table.insert(new_lines, path)
          end
        end
        vim.fn.writefile(new_lines, pf)
        print("Removed: " .. item.text)
        picker:close()
        -- Reopen if there are still files
        if #new_lines > 0 then
          vim.schedule(function()
            M.list()
          end)
        end
      end,
    },
    win = {
      input = {
        keys = {
          ["<c-x>"] = "delete",
        },
      },
    },
  }
end

-- Remove a pinned file
function M.remove()
  local pinned_file = get_pinned_file()

  if vim.fn.filereadable(pinned_file) == 0 then
    print "No pinned files"
    return
  end

  local lines = vim.fn.readfile(pinned_file)
  if #lines == 0 then
    print "No pinned files"
    return
  end

  vim.ui.select(lines, {
    prompt = "Remove pinned file:",
    format_item = function(item)
      return vim.fn.fnamemodify(item, ":~:.")
    end,
  }, function(choice)
    if choice then
      local new_lines = {}
      for _, path in ipairs(lines) do
        if path ~= choice then
          table.insert(new_lines, path)
        end
      end
      vim.fn.writefile(new_lines, pinned_file)
      print("Removed: " .. vim.fn.fnamemodify(choice, ":~:."))
    end
  end)
end

-- Clear list
function M.clear()
  local pinned_file = get_pinned_file()
  vim.fn.writefile({}, pinned_file)
  print "Cleared pinned files"
end

-- Keybindings
vim.keymap.set("n", "<leader>=a", M.add, { desc = "Pin current file" })
vim.keymap.set("n", "=", M.list, { desc = "List pinned files" })
vim.keymap.set("n", "<leader>=r", M.remove, { desc = "Remove pinned file" })
vim.keymap.set("n", "<leader>=c", M.clear, { desc = "Clear pinned files" })

return M
