vim.lsp.config("marksman", {
	on_attach = lsp_on_attach,
	capabilities = lsp_capabilities,
})
vim.lsp.enable("marksman")

require("conform").formatters_by_ft.markdown = { "prettier" }

-- Markdown-specific buffer settings applied on FileType
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true -- break at word boundaries
		vim.opt_local.spell = true
		vim.opt_local.spelllang = "en_gb"
		vim.opt_local.conceallevel = 2 -- render bold/italic markers
	end,
})
