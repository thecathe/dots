local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.tabstop = 2 -- tab size
opt.shiftwidth = 2 -- indentation size
opt.smarttab = true -- tab snaps to next indent
opt.expandtab = true -- replace tab with spaces
opt.termguicolors = true
opt.signcolumn = "yes" -- always show, prevents layout shifts
opt.updatetime = 250 -- faster CursorHold (used by LSP hover)
opt.splitright = true
opt.splitbelow = true
opt.undofile = true -- persistent undo across sessions
opt.mousemoveevent = true
opt.exrc = true -- project-local .nvim.lua config files

-- format
vim.keymap.set("n", "<leader>f", function()
	require("conform").format({ async = true })
end, { desc = "Format buffer" })

-- window width
vim.keymap.set("n", "<leader>w+", "5<C-w>>", { desc = "Widen window" })
vim.keymap.set("n", "<leader>w-", "5<C-w><", { desc = "Narrow window" })

-- indent/unindent single line
vim.keymap.set("n", "<S-Tab>", "<<", { noremap = true })
vim.keymap.set("i", "<S-Tab>", "<C-d>", { noremap = true })

-- indent/unindent visual selection
vim.keymap.set("v", "<Tab>", ">gv", { noremap = true })
vim.keymap.set("v", "<S-Tab>", "<gv", { noremap = true })

-- mini.starter
vim.keymap.set("n", "<leader>s", function()
	local starter = require("mini.starter")
	if vim.bo.filetype == "ministarter" then
		starter.close()
	else
		starter.open()
	end
end, { desc = "Toggle starter" })

-- lazy git/docker
-- vim.keymap.set("n", "<leader>g", function()
-- 	Snacks.lazygit()
-- end, { desc = "Lazygit" })
--
-- vim.keymap.set("n", "<leader>d", function()
-- 	Snacks.lazydocker()
-- end, { desc = "Lazydocker" })

if vim.g.neovide then
	-- cursor
	vim.opt.guicursor = table.concat({
		"n-v-c-sm:block-Cursor",
		"i-ci-ve:ver25-Cursor",
		"r-cr-o:hor20-Cursor",
		"t:block-blinkon500-blinkoff500-TermCursor",
	}, ",")

	vim.g.neovide_cursor_hack = false
	vim.g.neovide_cursor_alpha = 1.0
	vim.g.neovide_opacity = 1.0
	vim.g.neovide_cursor_vfx_mode = ""
	vim.g.neovide_cursor_trail_size = 1.0
	vim.g.neovide_cursor_animation_length = 0.08
	vim.g.neovide_scroll_animation_length = 0.2
	vim.g.neovide_cursor_cell_color_fallback = false
	vim.g.neovide_cursor_antialiasing = false

	-- cursor colors
	-- local function update_cursor()
	-- 	if vim.bo.filetype == "ministarter" then
	-- 		vim.api.nvim_set_hl(0, "Cursor", { fg = "#ebdbb2", bg = "#ebdbb2" })
	-- 	else
	-- 		vim.api.nvim_set_hl(0, "Cursor", { reverse = true })
	-- 	end
	-- end

	local current_cursor_mode = nil

	local function update_cursor()
		local is_starter = vim.bo.filetype == "ministarter"
		if is_starter == current_cursor_mode then
			return
		end
		current_cursor_mode = is_starter

		if is_starter then
			vim.api.nvim_set_hl(0, "Cursor", { fg = "#ebdbb2", bg = "#ebdbb2" })
		else
			vim.api.nvim_set_hl(0, "Cursor", { reverse = true })
		end
	end

	vim.api.nvim_create_autocmd("BufEnter", {
		callback = update_cursor,
	})

	vim.api.nvim_create_autocmd("UIEnter", {
		once = true,
		callback = function()
			vim.defer_fn(update_cursor, 200)
		end,
	})

	-- title
	vim.opt.title = true
	local parent = vim.env.KP_PARENT
	local cwd_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
	if parent and parent ~= "" then
		vim.opt.titlestring = parent .. " / " .. cwd_name
	else
		vim.opt.titlestring = cwd_name
	end
end
