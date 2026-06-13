require("mini.icons").setup()
MiniIcons.mock_nvim_web_devicons()

require("mini.pairs").setup()

require("mini.surround").setup({
	mappings = {
		add = "gsa", -- add surrounding, e.g. gsa" to wrap in quotes
		delete = "gsd", -- delete surrounding
		replace = "gsr", -- replace surrounding
		find = "gsf",
		find_left = "gsF",
		highlight = "gsh",
		update_n_lines = "gsn",
	},
})

require("mini.starter").setup({
	header = function()
		local branch = vim.fn.systemlist("git branch --show-current 2>/dev/null")[1]
		return branch and ("  " .. vim.fn.getcwd() .. "  (" .. branch .. ")") or vim.fn.getcwd()
	end,
	items = {
		function()
			local dir = get_session_dir()
			if vim.fn.isdirectory(dir) == 0 then
				return {}
			end
			local sessions = require("resession").list({ dir = dir })
			if not sessions then
				return {}
			end

			return vim.tbl_map(function(name)
				return {
					name = name,
					action = function()
						require("resession").load(name, { dir = dir })
					end,
					section = "Sessions",
				}
			end, sessions)
		end,
		function()
			-- recent files scoped to cwd only
			local cwd = vim.fn.getcwd()
			local oldfiles = vim.tbl_filter(function(f)
				return f:sub(1, #cwd) == cwd
			end, vim.v.oldfiles or {})
			return vim.tbl_map(function(path)
				return {
					name = vim.fn.fnamemodify(path, ":~:."),
					action = "edit " .. path,
					section = "Recent files",
				}
			end, vim.list_slice(oldfiles, 1, 5))
		end,
	},
})

-- move lines/selections with Alt+hjkl
require("mini.move").setup({
	mappings = {
		left = "<M-h>",
		right = "<M-l>",
		down = "<M-j>",
		up = "<M-k>",
		line_left = "<M-h>",
		line_right = "<M-l>",
		line_down = "<M-j>",
		line_up = "<M-k>",
	},
})

-- split/join arguments across lines with gS
require("mini.splitjoin").setup()
