-- Separators
local left_separator = ""
local right_separator = ""
-- Blank Between Components
local space = " "

local function TrimmedDirectory(dir)
	local home = os.getenv("HOME")
	local _, index = string.find(dir, home, 1)
	if index ~= nil and index ~= string.len(dir) then
		if string.len(dir) > 30 then
			dir = ".." .. string.sub(dir, 30)
		end
		return string.gsub(dir, home, "~")
	end
	return dir
end

local function set_colours()
	--SET TABLINE COLOURS
	vim.api.nvim_command("hi TabLineSel gui=Bold guibg=#5e81ac guifg=#e5e9f0")
	vim.api.nvim_command("hi TabLineSelSeparator gui=bold guifg=#5e81ac")
	vim.api.nvim_command("hi TabLine guibg=#4c566a guifg=#e5e9f0 gui=None")
	vim.api.nvim_command("hi TabLineSeparator guifg=#4c566a")
	vim.api.nvim_command("hi TabLineFill guibg=None gui=None")
end

local function any_bufs_modified(tab_nr)
	local wins = vim.api.nvim_tabpage_list_wins(tab_nr)
	for _, win in ipairs(wins) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].modified then
			return true
		end
	end
	return false
end

local function get_tab_label(n)
	local current_win = vim.api.nvim_tabpage_get_win(n)
	local current_buf = vim.api.nvim_win_get_buf(current_win)
	local file_name = vim.api.nvim_buf_get_name(current_buf)

	local modified = ""
	if any_bufs_modified(n) then
		modified = ""
	end

	local utils = require("utils")
	if string.find(file_name, "term://") ~= nil then
		return " " .. utils.sanitize_terminal_name(file_name)
	end

	file_name = vim.api.nvim_call_function("fnamemodify", { file_name, ":p:t" })
	if file_name == "" then
		-- To fix an issue when we have a cmdline open.
		-- In that case the filename is empty, so fallback to
		-- a buffer with an actual name
		local wins = vim.api.nvim_tabpage_list_wins(n)
		for _, win in ipairs(wins) do
			local buf = vim.api.nvim_win_get_buf(win)
			local buf_name = vim.api.nvim_buf_get_name(buf)
			buf_name = vim.api.nvim_call_function("fnamemodify", { buf_name, ":p:t" })
			if buf_name ~= "" then
				file_name = buf_name
				current_buf = buf
				break
			end
		end
	end

	if file_name == "" then
		return "No Name"
	end

	local icons = require("icons")
	local utils = require("utils")
	local icon = icons[utils.get_filetype(file_name)]
	if icon ~= nil then
		return icon .. space .. file_name .. modified
	end
	return file_name
end

function Tabline()
	set_colours()
	local tabline = ""
	local tab_list = vim.api.nvim_list_tabpages()
	local current_tab = vim.api.nvim_get_current_tabpage()
	for _, val in ipairs(tab_list) do
		local file_name = get_tab_label(val)
		if val == current_tab then
			tabline = tabline .. "%#TabLineSelSeparator# " .. left_separator
			tabline = tabline .. "%#TabLineSel# " .. file_name
			tabline = tabline .. " %#TabLineSelSeparator#" .. right_separator
		else
			tabline = tabline .. "%#TabLineSeparator# " .. left_separator
			tabline = tabline .. "%#TabLine# " .. file_name
			tabline = tabline .. " %#TabLineSeparator#" .. right_separator
		end
	end
	tabline = tabline .. "%="
	-- Component: Working Directory
	local dir = vim.api.nvim_call_function("getcwd", {})
	tabline = tabline
		.. "%#TabLineSeparator#"
		.. left_separator
		.. "%#Tabline# "
		.. TrimmedDirectory(dir)
		.. "%#TabLineSeparator#"
		.. right_separator
	tabline = tabline .. space
	return tabline
end

vim.o.tabline = "%!v:lua.Tabline()"
