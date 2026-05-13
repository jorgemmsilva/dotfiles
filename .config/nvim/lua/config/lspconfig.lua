local servers = {
  "html",
  "cssls",
  "gopls",
  "solidity_ls_nomicfoundation",
  "lua_ls",
  "tsgo",
  "tailwindcss",
  "eslint",
  -- "copilot",
}

-- diagnostics config
local sev = vim.diagnostic.severity
vim.diagnostic.config {
  virtual_text = { prefix = "" },
  signs = { text = { [sev.ERROR] = "󰅙", [sev.WARN] = "", [sev.INFO] = "󰋼", [sev.HINT] = "󰌵" } },
  underline = true,
  float = { border = "single" },
}

------------------------------------------------------------------
--- LUA
------------------------------------------------------------------

local lua_lsp_settings = {
  Lua = {
    runtime = { version = "LuaJIT" },
    workspace = {
      library = {
        vim.fn.expand "$VIMRUNTIME/lua",
        vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
        "${3rd}/luv/library",
      },
    },
  },
}

local lua_capabilities = vim.lsp.protocol.make_client_capabilities()
lua_capabilities.textDocument.completion.completionItem = {
  documentationFormat = { "markdown", "plaintext" },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  },
}

-- vim.lsp.config("*", {
--   capabilities = lua_capabilities,
--   on_init = function(client, _)
--     if client.supports_method "textDocument/semanticTokens" then
--       client.server_capabilities.semanticTokensProvider = nil
--     end
--   end,
-- })
vim.lsp.config("lua_ls", { settings = lua_lsp_settings })

------------------------------------------------------------------
--- TypeScript
------------------------------------------------------------------
vim.lsp.config("tsgo", {
  cmd = function(dispatchers, config)
    local cmd = "tsgo"

    if config and config.root_dir then
      local local_cmd = vim.fs.joinpath(config.root_dir, "node_modules/.bin", cmd)
      if vim.fn.executable(local_cmd) == 1 then
        cmd = local_cmd
      end
    end

    return vim.lsp.rpc.start({ cmd, "--lsp", "--stdio" }, dispatchers)
  end,
})

------------------------------------------------------------------
------------------------------------------------------------------
vim.lsp.enable(servers)
