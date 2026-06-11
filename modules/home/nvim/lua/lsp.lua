-- Exposed as _G globals so language modules (merged in via lib.mkAfter)
-- can reference them without requiring a separate Lua module.

_G.lsp_on_attach = function(client, bufnr)
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
  vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, { buffer = bufnr, desc = 'Signature help' })
  -- Enable inlay hints if the server supports them
  if client:supports_method('textDocument/inlayHint') then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    -- Keymap to toggle them on/off
    vim.keymap.set('n', '<leader>ih', function()
      vim.lsp.inlay_hint.enable(
        not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }),
        { bufnr = bufnr }
      )
    end, vim.tbl_extend('force', o, { desc = 'Toggle inlay hints' }))
  end
end

_G.lsp_capabilities = require('blink.cmp').get_lsp_capabilities()

-- ── nixd (Nix LSP) — always globally available ──────────────────────
vim.lsp.config('nixd', {
on_attach    = lsp_on_attach,
  capabilities = lsp_capabilities,
  settings = {
    nixd = {
      formatting = { command = { 'alejandra' } },
      nixpkgs = {
        -- Lets nixd evaluate nixpkgs for accurate package completions
        expr = '(builtins.getFlake "/home/cathe/dots").inputs.nixpkgs.legacyPackages.${builtins.currentSystem}',
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

-- notice fresh files
vim.lsp.config('*', {
  capabilities = {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
    },
  },
})
