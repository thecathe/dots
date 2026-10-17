vim.lsp.config("nixd", {
	on_attach = lsp_on_attach,
	capabilities = lsp_capabilities,
	settings = {
		nixd = {
			formatting = { command = { "alejandra" } },
			nixpkgs = {
				-- Lets nixd evaluate nixpkgs for accurate package completions
				expr = '@@NIXPKGS_EXPR@@',
			},
			-- NixOS / home-manager option completion; filled in from dots.nixd (modules/home/nixd.nix)
			options = @@OPTIONS@@,
		},
	},
})
vim.lsp.enable("nixd")
require("conform").formatters_by_ft.nix = { "alejandra" }
