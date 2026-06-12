require('conform').setup({
  format_on_save = {
    timeout_ms   = 500,
    lsp_fallback = false,  -- set to false temporarily to see if conform itself is running
  },
})

require('conform').formatters_by_ft.lua = { 'stylua' }
