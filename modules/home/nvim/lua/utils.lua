local M = {}

-- open pdfs in zathura
M.external_handlers = {
	pdf = "zathura",
	png = "xdg-open",
	jpg = "xdg-open",
	jpeg = "xdg-open",
	gif = "xdg-open",
	webp = "xdg-open",
}

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

patch_resession()

-- handle project-local sessions
M.get_session_dir = function()
	local result = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")
	if vim.v.shell_error == 0 and result[1] then
		return result[1] .. "/.nvim"
	end
	return vim.fn.getcwd() .. "/.nvim"
end

local function remap_session_paths(session_path)
	local current_home = vim.fn.expand("~")
	local content = vim.fn.readfile(session_path)
	local joined = table.concat(content, "\n")
	-- replace any /home/<whatever> prefix with current home
	local remapped = joined:gsub('"/home/[^/"]+', '"' .. current_home)
	vim.fn.writefile(vim.split(remapped, "\n"), session_path)
end

local function open_starter()
	-- Delay slightly so any pending UI events settle first
	vim.schedule(function()
		require("mini.starter").open()
	end)
end

M.handle_resession_load = function(session_name)
	session_name = session_name or "default"
	local dir = M.get_session_dir()
	local full_path = dir .. "/" .. session_name .. ".json"

	-- handle remapping session paths when on different machine
	if vim.fn.filereadable(full_path) == 0 then
		vim.notify("No session found at " .. full_path, vim.log.levels.WARN)
		open_starter()
		return
	end

	remap_session_paths(full_path)

	-- handle loading files we can't find
	local ok, err = pcall(require("resession").load, session_name, { dir = dir })
	if not ok then
		vim.notify("Session load failed: " .. err, vim.log.levels.WARN)
		open_starter()
		return
	end

	-- handle closing buffers for those we don't find
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local path = vim.api.nvim_buf_get_name(buf)
		if path ~= "" and vim.fn.filereadable(path) == 0 then
			vim.api.nvim_buf_delete(buf, { force = true })
		end
	end
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
