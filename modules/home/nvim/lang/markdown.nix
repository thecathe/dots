{ pkgs, lib, ... }:

# marksman is a standalone binary with no project coupling, so it's fine to
# install globally. prettier is kept optional — uncomment if you want global
# markdown formatting; otherwise add it to the relevant project devShells.

{
  programs.neovim = {
    extraPackages = with pkgs; [
      marksman # Markdown LSP: link completion, cross-references, headings
      prettier # uncomment for global Markdown formatting
    ];

    initLua = lib.mkAfter ''
      -- ── Markdown ────────────────────────────────────────────────────────
      require('lspconfig').marksman.setup({
        on_attach    = lsp_on_attach,
        capabilities = lsp_capabilities,
      })

      require('conform').formatters_by_ft.markdown = { 'prettier' }

      -- Markdown-specific buffer settings applied on FileType
      vim.api.nvim_create_autocmd('FileType', {
        pattern  = 'markdown',
        callback = function()
          vim.opt_local.wrap        = true
          vim.opt_local.linebreak   = true   -- break at word boundaries
          vim.opt_local.spell       = true
          vim.opt_local.spelllang   = 'en_gb'
          vim.opt_local.conceallevel = 2     -- render bold/italic markers
        end,
      })
    '';
  };
}
