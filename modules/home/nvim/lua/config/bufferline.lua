require("bufferline").setup({
	options = {
		mode = "buffers",
		separator_style = "thin",
		always_show_bufferline = true,
		show_close_icon = false,
		persist_buffer_sort = true,
		close_command = function(bufnr)
			Snacks.bufdelete(bufnr)
		end,
		right_mouse_command = function(bufnr)
			Snacks.bufdelete(bufnr)
		end,
		offsets = {
			{
				filetype = "snacks_explorer",
				text = "explorer",
				separator = true,
				text_align = "center",
			},
		},
	},
})

-- Navigate between buffers (tabs)
vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })

-- close buffer
vim.keymap.set("n", "<leader>bd", function()
	Snacks.bufdelete()
end, { desc = "Close buffer" })

-- Reorder
vim.keymap.set("n", "<leader>b>", "<cmd>BufferLineMoveNext<cr>", { desc = "Move buffer right" })
vim.keymap.set("n", "<leader>b<", "<cmd>BufferLineMovePrev<cr>", { desc = "Move buffer left" })

-- Pin
vim.keymap.set("n", "<leader>bp", "<cmd>BufferLineTogglePin<cr>", { desc = "Pin buffer" })
vim.keymap.set("n", "<leader>bP", "<cmd>BufferLineGroupClose unpinned<cr>", { desc = "Close unpinned" })

-- Jump to buffer by visible letter
vim.keymap.set("n", "<leader>bb", "<cmd>BufferLinePick<cr>", { desc = "Pick buffer" })
vim.keymap.set("n", "<leader>bc", "<cmd>BufferLinePickClose<cr>", { desc = "Pick buffer to close" })
