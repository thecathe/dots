vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	nested = true,
	callback = function()
		vim.cmd("packloadall") -- force pack loading if not already done
		local ok, configs = pcall(require, "nvim-treesitter.configs")
		if not ok then
			vim.notify("nvim-treesitter not found: " .. configs, vim.log.levels.WARN)
			return
		end
		configs.setup({
			highlight = { enable = true },
			indent = { enable = true },
		})
	end,
})
