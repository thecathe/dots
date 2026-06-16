require("snacks").setup({
	picker = {
		enabled = true,
		sources = {
			files = { exclude = { "**/_build/", "**/_build/**", "*/_build/*" } },
			explorer = {
				layout = { preset = "sidebar", preview = true, layout = { width = 25, position = "left" } },
				watch = true,
				auto_close = false,
				hidden = true,
				win = {
					keys = {
						["<cr>"] = {
							"open_keep_focus",
							action = function(picker, item)
								Snacks.picker.actions.jump(picker, item, {})
								vim.schedule(function()
									picker.list.win:focus()
								end)
							end,
							desc = "Open and keep explorer focus",
						},
						["<s-cr>"] = { "confirm", desc = "Open and focus file" },
					},
				},
			},
		},
	}, -- replaces telescope
	explorer = { enabled = true, trash = true }, -- sidebar file tree
	terminal = { enabled = true }, -- toggleable terminal
	notifier = { enabled = true }, -- replaces vim.notify
	indent = { enabled = true }, -- indent guides
	words = { enabled = true }, -- highlight word under cursor
	quickfile = { enabled = true }, -- faster file loading
	bigfile = { enabled = true }, -- disable heavy features on large files
	dashboard = { enabled = false },
})

-- close buffer
vim.keymap.set("n", "<leader>bd", function()
	Snacks.bufdelete()
end, { desc = "Delete buffer" })

-- Picker (replaces the telescope keymaps you had)
vim.keymap.set("n", "<leader>ff", function()
	Snacks.picker.files()
end, { desc = "Find files" })

vim.keymap.set("n", "<leader>fr", function()
	Snacks.picker.recent()
end, { desc = "Recent files" })

vim.keymap.set("n", "<leader>fg", function()
	Snacks.picker.grep()
end, { desc = "Grep" })

vim.keymap.set("n", "<leader>fb", function()
	Snacks.picker.buffers()
end, { desc = "Buffers" })

vim.keymap.set("n", "<leader>fd", function()
	Snacks.picker.diagnostics()
end, { desc = "Diagnostics" })

vim.keymap.set("n", "<leader>fR", function()
	Snacks.picker.lsp_references()
end, { desc = "LSP references" })

vim.keymap.set("n", "<leader>fs", function()
	Snacks.picker.lsp_symbols()
end, { desc = "LSP symbols" })

-- Explorer
vim.keymap.set("n", "<leader>e", function()
	Snacks.explorer()
end, { desc = "File explorer" })

-- Terminal toggle
vim.keymap.set("n", "<leader>t", function()
	Snacks.terminal()
end, { desc = "Toggle terminal" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
