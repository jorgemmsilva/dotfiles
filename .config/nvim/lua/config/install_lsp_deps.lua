local M = {}

M.treesitter_parsers = {
  "lua",
  "luadoc",
  "printf",
  "vim",
  "vimdoc",
  "nu",
  "typescript",
  "rust",
  "go",
  "toml",
  "json",
  "html",
  "css",
  "javascript",
  "markdown",
  "bash",
  "solidity",
}

M.mason_packages = {
  "lua-language-server",
  "html-lsp",
  "prettier",
  "stylua",
  "gopls",
  "rust-analyzer",
  "solhint",
  "nomicfoundation-solidity-language-server",
  "copilot-language-server",
  "typescript-language-server",
  "tailwindcss-language-server",
  "eslint-lsp",
  "codelldb",
}

--- Install all treesitter parsers and Mason packages.
--- Quits nvim when done. Intended for headless use (e.g. Docker build).
function M.install()
  local pending = 0

  local function on_done()
    pending = pending - 1
    if pending == 0 then
      vim.cmd "qa!"
    end
  end
  local safe_done = vim.schedule_wrap(on_done)

  -- Treesitter: track each parser that needs installing
  for _, lang in ipairs(M.treesitter_parsers) do
    if not pcall(vim.treesitter.language.inspect, lang) then
      pending = pending + 1
    end
  end
  if pending > 0 then
    local ts_remaining = pending
    vim.api.nvim_create_autocmd("User", {
      pattern = "TSInstall",
      callback = function()
        ts_remaining = ts_remaining - 1
        on_done()
        return ts_remaining == 0 -- remove autocmd when all parsers done
      end,
    })
  end
  require("nvim-treesitter").install(M.treesitter_parsers)

  -- Mason: track each package via install callbacks
  require("mason").setup { PATH = "append" }
  local registry = require "mason-registry"
  pending = pending + 1 -- hold for refresh
  registry.refresh(function()
    for _, name in ipairs(M.mason_packages) do
      local pkg = registry.get_package(name)
      if not pkg:is_installed() then
        pending = pending + 1
        pkg:once("install:success", safe_done)
        pkg:once("install:failed", safe_done)
        pkg:install()
      end
    end
    safe_done() -- release refresh hold
  end)
end

return M
