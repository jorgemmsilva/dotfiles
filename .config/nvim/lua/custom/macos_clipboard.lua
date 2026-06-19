-- macOS system clipboard (NSPasteboard) integration for file copy/paste.
--
-- Uses JXA (JavaScript for Automation) via `osascript -l JavaScript` to talk to
-- AppKit's NSPasteboard directly. This supports multiple files/dirs in both
-- directions and is Finder-compatible (files copied here paste in Finder, and
-- files copied in Finder paste here).
--
-- macOS only; every entry point is a harmless no-op elsewhere.

local M = {}

local uv = vim.uv or vim.loop

local function is_mac()
  return vim.fn.has "mac" == 1
end

local function notify_err(msg)
  vim.schedule(function()
    vim.notify("macos_clipboard: " .. msg, vim.log.levels.ERROR)
  end)
end

-- Reads newline-delimited POSIX paths from stdin and writes them to the
-- general pasteboard as file URLs (replacing the previous contents).
local WRITE_JS = [[
ObjC.import('AppKit');
ObjC.import('Foundation');
const data = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
const str = ObjC.unwrap($.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding)) || '';
const paths = str.split('\n').filter(function (p) { return p.length > 0; });
const pb = $.NSPasteboard.generalPasteboard;
pb.clearContents;
const urls = $.NSMutableArray.alloc.init;
paths.forEach(function (p) { urls.addObject($.NSURL.fileURLWithPath(p)); });
const ok = pb.writeObjects(urls);
// Give the pasteboard server time to commit every item before we exit;
// otherwise the last item is occasionally dropped on process teardown.
$.NSThread.sleepForTimeInterval(0.15);
ok ? 'ok' : 'fail';
]]

-- Emits newline-delimited POSIX paths for any file URLs on the pasteboard.
-- `FileURLsOnly` ensures plain text is not coerced into bogus paths.
local READ_JS = [[
ObjC.import('AppKit');
const pb = $.NSPasteboard.generalPasteboard;
const classes = $.NSArray.arrayWithObject($.NSURL.class);
const opts = $.NSDictionary.dictionaryWithObjectForKey($.NSNumber.numberWithBool(true), $.NSPasteboardURLReadingFileURLsOnlyKey);
const urls = pb.readObjectsForClassesOptions(classes, opts);
const out = [];
const n = (urls && urls.count) ? urls.count : 0;
for (let i = 0; i < n; i++) { out.push(ObjC.unwrap(urls.objectAtIndex(i).path)); }
out.join('\n');
]]

-- Clears the pasteboard only if it currently holds file URLs, so unrelated
-- copied text is left intact.
local CLEAR_JS = [[
ObjC.import('AppKit');
const pb = $.NSPasteboard.generalPasteboard;
const classes = $.NSArray.arrayWithObject($.NSURL.class);
const opts = $.NSDictionary.dictionaryWithObjectForKey($.NSNumber.numberWithBool(true), $.NSPasteboardURLReadingFileURLsOnlyKey);
if (pb.canReadObjectForClassesOptions(classes, opts)) { pb.clearContents; 'cleared'; } else { 'kept'; }
]]

local function osascript(js, sysopts, on_exit)
  vim.system(
    { "osascript", "-l", "JavaScript", "-e", js },
    vim.tbl_extend("force", { text = true }, sysopts or {}),
    on_exit
  )
end

---Write the given absolute paths to the macOS pasteboard as file URLs.
---@param paths string[]
function M.write_files(paths)
  if not is_mac() then
    notify_err "system clipboard file copy is only supported on macOS"
    return
  end
  if not paths or #paths == 0 then
    return
  end
  osascript(WRITE_JS, { stdin = table.concat(paths, "\n") }, function(res)
    if res.code ~= 0 then
      notify_err("failed to write pasteboard: " .. (res.stderr or ""))
    end
  end)
end

---Read file paths currently on the macOS pasteboard.
---@param cb fun(files: string[])
function M.read_files(cb)
  if not is_mac() then
    cb {}
    return
  end
  osascript(READ_JS, {}, function(res)
    local files = {}
    if res.code == 0 and res.stdout then
      for line in res.stdout:gmatch "[^\n]+" do
        line = vim.trim(line)
        if line ~= "" then
          table.insert(files, line)
        end
      end
    end
    vim.schedule(function()
      cb(files)
    end)
  end)
end

---Clear the pasteboard if (and only if) it holds file URLs.
function M.clear_file_refs()
  if not is_mac() then
    return
  end
  osascript(CLEAR_JS, {}, function() end)
end

local function path_exists(p)
  return uv.fs_stat(p) ~= nil
end

-- Finder-style collision-free destination: "name", then "name copy",
-- "name copy 2", ... inserting before the extension for files.
local function unique_dest(dir, name)
  local dest = dir .. "/" .. name
  if not path_exists(dest) then
    return dest
  end

  local base, ext = name:match "^(.+)(%.[^.]+)$"
  if not base then
    base, ext = name, ""
  end

  local function make(suffix)
    return dir .. "/" .. base .. suffix .. ext
  end

  local candidate = make " copy"
  if not path_exists(candidate) then
    return candidate
  end

  local i = 2
  while true do
    candidate = make(" copy " .. i)
    if not path_exists(candidate) then
      return candidate
    end
    i = i + 1
  end
end

---Copy the given source paths into `dir` (recursively), auto-renaming on
---collision. Invokes `cb(copied_count)` when all copies finish.
---@param files string[]
---@param dir string
---@param cb fun(copied: integer)?
function M.copy_files(files, dir, cb)
  if not files or #files == 0 then
    if cb then
      cb(0)
    end
    return
  end

  local copied = 0
  local pending = #files

  local function done()
    pending = pending - 1
    if pending == 0 and cb then
      cb(copied)
    end
  end

  for _, src in ipairs(files) do
    local clean = src:gsub("/+$", "")
    local name = vim.fn.fnamemodify(clean, ":t")
    local dest = unique_dest(dir, name)
    vim.system({ "cp", "-R", clean, dest }, { text = true }, function(res)
      if res.code == 0 then
        copied = copied + 1
      else
        notify_err("failed to copy " .. clean .. ": " .. (res.stderr or ""))
      end
      done()
    end)
  end
end

-- Absolute paths for the current selection: all nodes in the visual range, or
-- just the node under the cursor in normal mode.
local function collect_paths(api)
  local mode = vim.fn.mode()
  local paths = {}
  if mode == "v" or mode == "V" or mode == "\22" then
    local s, e = vim.fn.line "v", vim.fn.line "."
    if s > e then
      s, e = e, s
    end
    local core = require "nvim-tree.core"
    local explorer = core.get_explorer()
    if explorer then
      local nodes_by_line = explorer:get_nodes_by_line(core.get_nodes_starting_line())
      for line = s, e do
        local node = nodes_by_line[line]
        if node and node.absolute_path and node.name ~= ".." then
          table.insert(paths, node.absolute_path)
        end
      end
    end
    -- leave visual mode
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  else
    local node = api.tree.get_node_under_cursor()
    if node and node.absolute_path and node.name ~= ".." then
      table.insert(paths, node.absolute_path)
    end
  end
  return paths
end

-- Directory to paste into: the node's dir (or its parent if it's a file),
-- falling back to the tree root.
local function target_dir(api)
  local node = api.tree.get_node_under_cursor()
  if node and node.absolute_path and node.name ~= ".." then
    if node.type == "directory" then
      return node.absolute_path
    end
    return vim.fn.fnamemodify(node.absolute_path, ":h")
  end
  return require("nvim-tree.core").get_cwd()
end

---Install the system-clipboard c/x/p overrides on an nvim-tree buffer.
---Intended to be called from nvim-tree's `on_attach` (macOS only).
---@param bufnr integer
function M.setup_nvim_tree_keymaps(bufnr)
  local api = require "nvim-tree.api"

  -- c: copy selection to the macOS system clipboard (paste in Finder or back
  -- here with p). Works on a single node or a visual selection.
  vim.keymap.set({ "n", "x" }, "c", function()
    local paths = collect_paths(api)
    if #paths == 0 then
      return
    end
    M.write_files(paths)
    vim.notify(("Copied %d item%s to clipboard"):format(#paths, #paths == 1 and "" or "s"))
  end, { buffer = bufnr, noremap = true, silent = true, desc = "Copy to system clipboard" })

  -- x: internal cut, and clear file refs from the system clipboard so a
  -- following p performs the move rather than a stale paste.
  vim.keymap.set({ "n", "x" }, "x", function()
    api.fs.cut()
    M.clear_file_refs()
  end, { buffer = bufnr, noremap = true, silent = true, desc = "Cut (clears system clipboard files)" })

  -- p: seamless paste. If the system clipboard holds files (from c or from
  -- Finder) paste those; otherwise fall back to the internal clipboard (i.e.
  -- complete a cut/move).
  vim.keymap.set("n", "p", function()
    local dir = target_dir(api)
    M.read_files(function(files)
      if #files > 0 then
        M.copy_files(files, dir, function(n)
          if n > 0 then
            api.tree.reload()
            vim.notify(("Pasted %d item%s"):format(n, n == 1 and "" or "s"))
          end
        end)
      else
        api.fs.paste()
      end
    end)
  end, { buffer = bufnr, noremap = true, silent = true, desc = "Paste (system clipboard or internal)" })
end

return M
