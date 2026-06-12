local function get_project_dir()
	local result = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")
	if vim.v.shell_error == 0 and result[1] then
		return result[1] .. "/.nvim"
	end
	return nil
end

-- returns { dir = ... } when in a git repo, {} otherwise (falls back to resession default)
local function session_opts()
	local dir = get_project_dir()
	return dir and { dir = dir } or {}
end

require("resession").setup({
	autosave = {
		enabled = true,
		interval = 60,
		notify = true,
	},
})

vim.api.nvim_create_user_command("SSave", function(opts)
	require("resession").save(opts.args ~= "" and opts.args or nil, session_opts())
end, { nargs = "?" })

vim.api.nvim_create_user_command("SLoad", function(opts)
	require("resession").load(opts.args ~= "" and opts.args or nil, session_opts())
end, { nargs = "?" })

vim.api.nvim_create_user_command("SDelete", function(opts)
	require("resession").delete(opts.args ~= "" and opts.args or nil, session_opts())
end, { nargs = "?" })

-- VimEnter fallback
vim.api.nvim_create_autocmd("VimEnter", {
	nested = true,
	callback = function()
		if vim.fn.argc() ~= 0 then
			return
		end

		local dir = get_project_dir()
		if not dir then
			return
		end -- not in a git repo, open normally

		local sessions = require("resession").list({ dir = dir })
		if not sessions or #sessions == 0 then
			return
		end

		if #sessions == 1 then
			require("resession").load(sessions[1], { dir = dir })
		else
			require("resession").load(nil, { dir = dir }) -- opens picker
		end
	end,
})
