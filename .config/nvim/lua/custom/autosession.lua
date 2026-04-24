local M = {}

local suppressed_dirs = { "~/Downloads", "/" }

local function percent_encode(str)
  return (str:gsub("([/\\:*?\"'<>+ |%.%%])", function(c)
    return string.format("%%%02X", string.byte(c))
  end))
end

local function get_session_dir()
  local dir = vim.fn.stdpath "data" .. "/sessions"
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  return dir
end

local function get_session_file()
  local cwd = vim.env.NV_HOST_DIR or vim.fn.getcwd()
  return get_session_dir() .. "/" .. percent_encode(cwd) .. ".vim"
end

local function is_suppressed()
  local cwd = vim.fn.getcwd()
  for _, dir in ipairs(suppressed_dirs) do
    local expanded = vim.fn.expand(dir)
    if cwd == expanded then
      return true
    end
  end
  return false
end

function M.save()
  if is_suppressed() or vim.env.NVIM_EPHEMERAL then
    return
  end
  vim.cmd("mksession! " .. vim.fn.fnameescape(get_session_file()))
end

function M.restore()
  if vim.fn.argc() > 0 or vim.env.NVIM_EPHEMERAL then
    return
  end
  local session_file = get_session_file()
  if vim.fn.filereadable(session_file) == 1 then
    vim.cmd("source " .. vim.fn.fnameescape(session_file))
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("AutoSession", { clear = true })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = M.save,
  })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    nested = true,
    callback = M.restore,
  })
end

return M
