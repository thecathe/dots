require("resession").setup({
	autosave = { enabled = false },
})

local utils = require("utils")

local function get_session_dir()
	return utils.get_session_dir()
end -- only used by SSave

local function ensure_session_dir()
	local dir = get_session_dir()
	vim.fn.mkdir(dir, "p")
	return dir
end

vim.api.nvim_create_user_command("SSave", function(opts)
	local dir = ensure_session_dir() -- creates /.nvim if needed
	require("resession").save(opts.args ~= "" and opts.args or nil, { dir = dir })
end, { nargs = "?" })

local function handle_resession_load(opts)
	utils.handle_resession_load(opts.args ~= "" and opts.args or nil)
end

vim.api.nvim_create_user_command("SLoad", function(opts)
	return handle_resession_load(opts)
end, { nargs = "?" })

vim.api.nvim_create_user_command("SDelete", function(opts)
	require("resession").delete(opts.args ~= "" and opts.args or nil, { dir = get_session_dir() })
end, { nargs = "?" })
