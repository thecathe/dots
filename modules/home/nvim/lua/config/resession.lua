local function get_session_dir()
	local result = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")
	if vim.v.shell_error == 0 and result[1] then
		return result[1] .. "/.nvim"
	end
	return vim.fn.getcwd() .. "/.nvim"
end

-- only used by SSave
local function ensure_session_dir()
	local dir = get_session_dir()
	vim.fn.mkdir(dir, "p")
	return dir
end

-- returns { dir = ... } when in a git repo, {} otherwise (falls back to resession default)
local function session_opts()
	local dir = get_project_dir()
	return dir and { dir = dir } or {}
end

require("resession").setup({
	autosave = {
		enabled = false,
		interval = 60,
		notify = true,
	},
})

vim.api.nvim_create_user_command("SSave", function(opts)
	local dir = ensure_session_dir() -- creates /.nvim if needed
	require("resession").save(opts.args ~= "" and opts.args or nil, { dir = dir })
end, { nargs = "?" })

vim.api.nvim_create_user_command("SLoad", function(opts)
	require("resession").load(opts.args ~= "" and opts.args or nil, { dir = get_project_dir() })
end, { nargs = "?" })

vim.api.nvim_create_user_command("SDelete", function(opts)
	require("resession").delete(opts.args ~= "" and opts.args or nil, { dir = get_project_dir() })
end, { nargs = "?" })

-- VimEnter fallback
vim.api.nvim_create_autocmd("VimEnter", {
	nested = true,
	callback = function()
		if vim.fn.argc() ~= 0 then
			return
		end

		local dir = get_project_dir()

		-- bail out if the directory doesn't exist yet — no sessions saved here
		if vim.fn.isdirectory(dir) == 0 then
			return
		end

		local sessions = require("resession").list({ dir = dir })
		if not sessions or #sessions == 0 then
			return
		end

		if #sessions == 1 then
			require("resession").load(sessions[1], { dir = dir })
			return
		end

		local latest, latest_time = nil, 0
		for _, name in ipairs(sessions) do
			local path = dir .. "/" .. name .. ".json"
			local stat = vim.loop.fs_stat(path)
			if stat and stat.mtime.sec > latest_time then
				latest = name
				latest_time = stat.mtime.sec
			end
		end

		if latest then
			require("resession").load(latest, { dir = dir })
		else
			require("resession").load(nil, { dir = dir }) -- opens picker
		end
	end,
})
