-- always read contents of bin/ as bash files
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = "bin/*",
	callback = function()
		if vim.bo.filetype == "" then
			vim.bo.filetype = "bash"
		end
	end,
})
