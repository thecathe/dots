vim.lsp.config("nixd", {
	on_attach = lsp_on_attach,
	capabilities = lsp_capabilities,
	settings = {
		nixd = {
			formatting = { command = { "alejandra" } },
			nixpkgs = {
				-- Lets nixd evaluate nixpkgs for accurate package completions
				expr = '(builtins.getFlake "@@DOTS_PATH@@").inputs.nixpkgs.legacyPackages.${builtins.currentSystem}',
			},
			options = {
				nixos = {
					expr = '(builtins.getFlake "@@DOTS_PATH@@").nixosConfigurations.nixos.options',
				},
				home_manager = {
					expr = '(builtins.getFlake "@@DOTS_PATH@@").homeConfigurations."cathe@worklaptop".options',
				},
			},
		},
	},
})
vim.lsp.enable("nixd")
require("conform").formatters_by_ft.nix = { "alejandra" }
