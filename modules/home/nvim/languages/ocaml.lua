require('lspconfig').ocamllsp.setup({
  on_attach    = lsp_on_attach,
  capabilities = lsp_capabilities,
  settings = {
    codelens   = { enable = true },
    inlayHints = { enable = true },
  },
})
require('conform').formatters_by_ft.ocaml = { 'ocamlformat' }
