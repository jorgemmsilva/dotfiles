vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    -- Mark terminal buffers as "unlisted" so they don't show in bufferline
    vim.opt_local.buflisted = false
  end,
})
