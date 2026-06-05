vim.lsp.config('ocamllsp', {
  on_attach    = lsp_on_attach,
  capabilities = lsp_capabilities,
  settings = {
    codelens   = { enable = true },
    inlayHints = { enable = true },
  },
})
vim.lsp.enable('ocamllsp')
require('conform').formatters_by_ft.ocaml = { 'ocamlformat' }
