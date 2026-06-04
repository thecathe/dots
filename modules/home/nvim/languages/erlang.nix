{ lib, ... }:
{
  programs.neovim.extraLuaConfig = lib.mkAfter ''
    -- ── Erlang ─────────────────────────────────────────────────────────────
    require('lspconfig').erlangls.setup({
      on_attach    = lsp_on_attach,
      capabilities = lsp_capabilities,
    })

    -- erlang-ls does not support formatting; use erlfmt if available in PATH.
    -- Add it to your devShell and uncomment:
    -- require('conform').formatters_by_ft.erlang = { 'erlfmt' }
  '';
}
