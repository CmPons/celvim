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

local function sanitize_terminal_name(buf_name)
	print("sanitize_terminal_name " .. buf_name)
	local buf = buf_name:gsub("term://", "")
	print("buf " .. buf)
	local prog = vim.split(buf, ":", { trimempty = true })
	print("prog num " .. #prog .. " " .. prog[2])
	if #prog < 2 then
		return buf_name
	end

	local prog_name = vim.split(prog[2], " ")[1]
	print("Prog name " .. tostring(prog_name))

	if prog_name:find("/") then
		local short_name = vim.split(prog_name, "/")
		print("Short name " .. tostring(short_name[#short_name]))
		if #short_name > 1 then
			return short_name[#short_name]
		end
	end

	return prog_name
end

local function get_tab_label(n)
	local current_win = vim.api.nvim_tabpage_get_win(n)
	local current_buf = vim.api.nvim_win_get_buf(current_win)
	local file_name = vim.api.nvim_buf_get_name(current_buf)
	if string.find(file_name, "term://") ~= nil then
		return " " .. sanitize_terminal_name(file_name)
	end

	file_name = vim.api.nvim_call_function("fnamemodify", { file_name, ":p:t" })
	if file_name == "" then
		return "No Name"
	end

	local icons = require("icons")
	local utils = require("utils")
	local icon = icons[utils.get_filetype(file_name)]
	if icon ~= nil then
		return icon .. space .. file_name
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
