local M = {}

-- handle project-local sessions
M.get_session_dir = function()
	local result = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")
	if vim.v.shell_error == 0 and result[1] then
		return result[1] .. "/.nvim"
	end
	return vim.fn.getcwd() .. "/.nvim"
end

-- handle flake urls
M.open_url = function()
	local line = vim.fn.getline(".")
	local col = vim.fn.col(".")

	-- try nix flake pattern: site:owner/repo
	for site, path in line:gmatch("([%a][%w%-]*):([%w%-%.]+/[%w%-%.]+)") do
		local match_start, match_end = line:find(site .. ":" .. path, 1, true)
		if match_start and col >= match_start and col <= match_end then
			vim.ui.open("https://" .. site .. ".com/" .. path)
			return
		end
	end

	-- fall back to default behaviour for regular URLs
	vim.ui.open(vim.fn.expand("<cfile>"))
end

return M
