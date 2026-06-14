require("render-markdown").setup({
	heading = {
		icons = { "󰬺 ", "󰬻 ", "󰬼 ", "󰬽 ", "󰬾 ", "󰬿 " },
		width = "full",
		backgrounds = {
			"RenderMarkdownH1Bg",
			"RenderMarkdownH2Bg",
			"RenderMarkdownH3Bg",
			"RenderMarkdownH4Bg",
			"RenderMarkdownH5Bg",
			"RenderMarkdownH6Bg",
		},
	},
	code = { enabled = true, width = "block", border = "thick" },
	bullet = { enabled = true },
	checkbox = { enabled = true },
	table = { enabled = true },
})

-- vim.api.nvim_set_hl(0, "RenderMarkdownH1", { fg = "#cba6f7", bold = true })
-- vim.api.nvim_set_hl(0, "RenderMarkdownH2", { fg = "#89b4fa", bold = true })
-- vim.api.nvim_set_hl(0, "RenderMarkdownH3", { fg = "#94e2d5", bold = true })
-- vim.api.nvim_set_hl(0, "RenderMarkdownH4", { fg = "#a6e3a1" })
-- vim.api.nvim_set_hl(0, "RenderMarkdownH5", { fg = "#f9e2af" })
-- vim.api.nvim_set_hl(0, "RenderMarkdownH6", { fg = "#f38ba8" })
-- vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = "#2a1f3d" })
-- vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { bg = "#1e2b3d" })
-- vim.api.nvim_set_hl(0, "RenderMarkdownH3Bg", { bg = "#1a2d2b" })

local function apply_markdown_highlights()
	-- Foregrounds: link to gruvbox's named palette groups
	vim.api.nvim_set_hl(0, "RenderMarkdownH1", { link = "GruvboxRedBold" })
	vim.api.nvim_set_hl(0, "RenderMarkdownH2", { link = "GruvboxOrangeBold" })
	vim.api.nvim_set_hl(0, "RenderMarkdownH3", { link = "GruvboxYellowBold" })
	vim.api.nvim_set_hl(0, "RenderMarkdownH4", { link = "GruvboxGreenBold" })
	vim.api.nvim_set_hl(0, "RenderMarkdownH5", { link = "GruvboxAquaBold" })
	vim.api.nvim_set_hl(0, "RenderMarkdownH6", { link = "GruvboxBlueBold" })

	-- -- Backgrounds: derive from the fg of each gruvbox group
	-- local palette = {
	--   'GruvboxRedBold', 'GruvboxOrangeBold', 'GruvboxYellowBold',
	--   'GruvboxGreenBold', 'GruvboxAquaBold', 'GruvboxBlueBold',
	-- }
	-- for i, source in ipairs(palette) do
	--   local hl = vim.api.nvim_get_hl(0, { name = source, link = false })
	--   if hl.fg then
	--     -- use the gruvbox colour as a very dim background
	--     vim.api.nvim_set_hl(0, 'RenderMarkdownH' .. i .. 'Bg', {
	--       bg = string.format('#%06x', hl.fg),
	--     })
	--   end
	-- end

	local ok, colors = pcall(require, "gruvbox.palette")
	if ok then
		local bg = colors.get_base_colors(vim.o.background, "hard")
		vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = bg.dark1 })
		-- etc.
	end
end

-- Apply immediately and whenever the colorscheme is reloaded
apply_markdown_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = apply_markdown_highlights,
})
