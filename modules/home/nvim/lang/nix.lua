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
require('conform').formatters_by_ft.nix = { 'alejandra' }

