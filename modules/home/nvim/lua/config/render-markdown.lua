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
	-- gruvbox bright colours, cascade from warm to cool
	local fg = {
		"#fb4934", -- H1: bright red
		"#fe8019", -- H2: bright orange
		"#fabd2f", -- H3: bright yellow
		"#b8bb26", -- H4: bright green
		"#8ec07c", -- H5: bright aqua
		"#83a598", -- H6: bright blue
	}

	local function hex_to_rgb(hex)
		hex = hex:gsub("#", "")
		return {
			r = tonumber(hex:sub(1, 2), 16),
			g = tonumber(hex:sub(3, 4), 16),
			b = tonumber(hex:sub(5, 6), 16),
		}
	end

	local function blend(hex1, hex2, t)
		local c1 = hex_to_rgb(hex1)
		local c2 = hex_to_rgb(hex2)
		return string.format(
			"#%02x%02x%02x",
			math.floor(c1.r + (c2.r - c1.r) * t + 0.5),
			math.floor(c1.g + (c2.g - c1.g) * t + 0.5),
			math.floor(c1.b + (c2.b - c1.b) * t + 0.5)
		)
	end

	local bg_top = "#504945" -- gruvbox bg2: most prominent
	local bg_base = "#1d2021" -- gruvbox bg hard: base background

	for i, color in ipairs(fg) do
		-- t: 0 at H1 (full bg_top) → 0.9 at H6 (barely above base)
		local t = (i - 1) / #fg * 0.9
		vim.api.nvim_set_hl(0, "RenderMarkdownH" .. i, {
			fg = color,
			bold = i <= 2,
		})
		vim.api.nvim_set_hl(0, "RenderMarkdownH" .. i .. "Bg", {
			bg = blend(bg_top, bg_base, t),
		})
	end
end

-- Apply immediately and whenever the colorscheme is reloaded
apply_markdown_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = apply_markdown_highlights,
})
