local utils = require("utils")

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
		vim.opt_local.tabstop = 2
		vim.opt_local.shiftwidth = 2
		vim.opt_local.expandtab = true

		-- follow link
		vim.keymap.set("n", "gf", function()
			local line = vim.api.nvim_get_current_line()
			local col = vim.api.nvim_win_get_cursor(0)[2] + 1

			-- extract link target from markdown syntax [text](target)
			local link
			local s = 1
			while true do
				local lhs, rhs, url = line:find("%[.-%]%((.-)%)", s)
				if not lhs then
					break
				end
				if col >= lhs and col <= rhs then
					link = url
					break
				end
				s = lhs + 1
			end

			-- also try bare paths under cursor as fallback
			link = link or vim.fn.expand("<cfile>")

			if not link or link == "" then
				vim.notify("Link not found under cursor", vim.log.levels.WARN)
				return
			end

			-- strip fragment (#heading) before any path operations
			local raw_path, fragment = link:match("^([^#]*)(#?.*)$")
			if raw_path == "" then
				raw_path = link
			end

			-- decode percent-encoding (%20 → space etc.)
			local path = link:gsub("%%(%x%x)", function(hex)
				return string.char(tonumber(hex, 16))
			end)

			-- resolve relative to current file's directory
			local fullpath = vim.fn.fnamemodify(vim.fn.expand("%:p:h") .. "/" .. path, ":p")
			local ext = fullpath:match("%.(%w+)$")

			if ext and utils.external_handlers[ext] then
				vim.fn.jobstart({ utils.external_handlers[ext], fullpath }, { detach = true })
				return
			end

			-- open in neovim and jump to heading if present
			vim.cmd("edit " .. vim.fn.fnameescape(fullpath))
			if fragment and fragment ~= "" then
				local heading = fragment:sub(2) -- drop the leading #
				local pattern = "^#+ " .. heading:gsub("-", "."):gsub("%%20", " ")
				vim.fn.search(pattern, "w")
			end
		end, { buffer = true, desc = "Follow markdown link" })
	end,
})
