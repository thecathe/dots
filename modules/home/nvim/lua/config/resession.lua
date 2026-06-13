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

-- VimEnter fallback
-- vim.api.nvim_create_autocmd("VimEnter", {
-- 	nested = true,
-- 	callback = function()
-- 		if vim.fn.argc() ~= 0 then
-- 			return
-- 		end
--
-- 		local dir = get_project_dir()
--
-- 		-- bail out if the directory doesn't exist yet — no sessions saved here
-- 		if vim.fn.isdirectory(dir) == 0 then
-- 			return
-- 		end
--
-- 		local sessions = require("resession").list({ dir = dir })
-- 		if not sessions or #sessions == 0 then
-- 			return
-- 		end
--
-- 		if #sessions == 1 then
-- 			require("resession").load(sessions[1], { dir = dir })
-- 			return
-- 		end
--
-- 		local latest, latest_time = nil, 0
-- 		for _, name in ipairs(sessions) do
-- 			local path = dir .. "/" .. name .. ".json"
-- 			local stat = vim.loop.fs_stat(path)
-- 			if stat and stat.mtime.sec > latest_time then
-- 				latest = name
-- 				latest_time = stat.mtime.sec
-- 			end
-- 		end
--
-- 		if latest then
-- 			require("resession").load(latest, { dir = dir })
-- 		else
-- 			require("resession").load(nil, { dir = dir }) -- opens picker
-- 		end
-- 	end,
-- })
