-- Exposed as _G globals so language modules (merged in via lib.mkAfter)
-- can reference them without requiring a separate Lua module.

_G.lsp_on_attach = function(_, bufnr)
  local o = { buffer = bufnr, silent = true }
  vim.keymap.set('n', 'gd',         vim.lsp.buf.definition,        o)
  vim.keymap.set('n', 'gD',         vim.lsp.buf.declaration,       o)
  vim.keymap.set('n', 'gr',         vim.lsp.buf.references,        o)
  vim.keymap.set('n', 'gi',         vim.lsp.buf.implementation,    o)
  vim.keymap.set('n', 'K',          vim.lsp.buf.hover,             o)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename,            o)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action,       o)
  vim.keymap.set('n', '[d',         vim.diagnostic.goto_prev,      o)
  vim.keymap.set('n', ']d',         vim.diagnostic.goto_next,      o)
  vim.keymap.set('n', '<leader>f',  function()
    require('conform').format({ bufnr = bufnr })
  end, vim.tbl_extend('force', o, { desc = 'Format buffer' }))
end

_G.lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()

-- ── nixd (Nix LSP) — always globally available ──────────────────────
vim.lsp.config('nixd', {
on_attach    = lsp_on_attach,
  capabilities = lsp_capabilities,
  settings = {
    nixd = {
      formatting = { command = { 'alejandra' } },
      nixpkgs = {
        -- Lets nixd evaluate nixpkgs for accurate package completions
        expr = 'import <nixpkgs> { }',
      },
      options = {
        nixos = {
          expr = '(builtins.getFlake "/home/cathe/dots").nixosConfigurations.mymachine.options',
        },
        home_manager = {
          expr = '(builtins.getFlake "/home/cathe/dots").homeConfigurations.cathe.options',
        },
      },
    },
  },
})
vim.lsp.enable('nixd')

