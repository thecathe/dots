-- patch resession to support absolute paths for dir
local function patch_resession()
	local util = require("resession.util")
	local original = util.get_session_dir
	util.get_session_dir = function(dirname)
		if dirname and dirname:sub(1, 1) == "/" then
			return dirname -- treat as absolute, bypass stdpath prepending
		end
		return original(dirname)
	end
end

require("resession").setup({
	autosave = { enabled = false },
})

patch_resession()

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

vim.api.nvim_create_user_command("SLoad", function(opts)
	require("resession").load(opts.args ~= "" and opts.args or nil, { dir = get_session_dir() })
end, { nargs = "?" })

vim.api.nvim_create_user_command("SDelete", function(opts)
	require("resession").delete(opts.args ~= "" and opts.args or nil, { dir = get_session_dir() })
end, { nargs = "?" })
