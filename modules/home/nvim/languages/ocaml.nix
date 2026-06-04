{ lib, ... }:
{
  programs.neovim.initLua = lib.mkAfter ''
    -- ── OCaml ──────────────────────────────────────────────────────────────
    require('lspconfig').ocamllsp.setup({
      on_attach    = lsp_on_attach,
      capabilities = lsp_capabilities,
      settings = {
        -- Inline type hints and codelens are useful for OCaml's inferred types
        codelens   = { enable = true },
        inlayHints = { enable = true },
      },
    })

    -- ocamlformat reads .ocamlformat at the project root for style settings,
    -- so no formatter config is needed here.
    require('conform').formatters_by_ft.ocaml = { 'ocamlformat' }
  '';
}
