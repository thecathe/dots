 -- Show diagnostic float automatically when cursor pauses
vim.api.nvim_create_autocmd('CursorHold', {
  callback = function()
    vim.diagnostic.open_float(nil, { focus = false, border = 'rounded' })
  end,
})

-- Configure how diagnostics are displayed
vim.diagnostic.config({
  virtual_text  = { prefix = '●', severity = { min = vim.diagnostic.severity.WARN } },
  signs         = true,
  underline     = true,
  severity_sort = true,
  float         = { border = 'rounded', source = true },
})

