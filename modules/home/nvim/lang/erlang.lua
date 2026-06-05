vim.lsp.config('erlangls', {
on_attach    = lsp_on_attach,
capabilities = lsp_capabilities,
})
vim.lsp.enable('erlangls')

-- erlang-ls does not support formatting; use erlfmt if available in PATH.
-- Add it to your devShell and uncomment:
require('conform').formatters_by_ft.erlang = { 'erlfmt' }

