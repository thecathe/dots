local M = {}

M.get_session_dir = function()
	local result = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")
	if vim.v.shell_error == 0 and result[1] then
		return result[1] .. "/.nvim"
	end
	return vim.fn.getcwd() .. "/.nvim"
end

return M
