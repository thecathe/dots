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

		-- follow link
		vim.keymap.set("n", "gf", function()
			local line = vim.api.nvim_get_current_line()
			local col = vim.api.nvim_win_get_cursor(0)[2] + 1

			-- extract link target from markdown syntax [text](target)
			local link
			for text, url in line:gmatch("%[.-%]%((.-)%)") do
				link = text
				break
			end

			-- also try bare paths under cursor as fallback
			link = link or vim.fn.expand("<cfile>")

			if not link or link == "" then
				vim.notify("no link found under cursor", vim.log.levels.WARN)
				return
			end

			-- decode percent-encoding (%20 → space etc.)
			local path = link:gsub("%%(%x%x)", function(hex)
				return string.char(tonumber(hex, 16))
			end)

			-- resolve relative to current file's directory
			local fullpath = vim.fn.fnamemodify(vim.fn.expand("%:p:h") .. "/" .. path, ":p")

			local ext = fullpath:match("%.(%w+)$")

			vim.cmd("edit " .. vim.fn.fnameescape(fullpath))
		end, { buffer = true, desc = "Follow markdown link" })
	end,
})
