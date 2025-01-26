local M = {}

M.win_size = {}

M.pos_from_screen_percent = function(percent)
	return { row = math.floor(M.win_size.row * percent.row), col = math.floor(M.win_size.col * percent.col) }
end

M.get_syntax_from_filetype = function(filetype)
	if filetype == "rs" then
		return "rust"
	end

	return filetype
end

M.get_filetype = function(file_name)
	local ext = file_name:match("^.+(%..+)$")
	if ext == nil then
		return ""
	end

	return ext:sub(2, #ext)
end

M.sanitize_terminal_name = function(buf_name)
	local buf = buf_name:gsub("term://", "")
	local prog = vim.split(buf, ":", { trimempty = true })
	if #prog < 2 then
		return buf_name
	end

	local prog_name = vim.split(prog[2], " ")[1]

	if prog_name:find("/") then
		local short_name = vim.split(prog_name, "/")
		if #short_name > 1 then
			return short_name[#short_name]
		end
	end

	return prog_name
end

M.get_curr_date_time = function()
	return os.date("%c")
end

M.dump_table = function(tbl, indent)
	indent = indent or 0
	for k, v in pairs(tbl) do
		print(string.rep(" ", indent) .. tostring(k) .. ":")
		if type(v) == "table" then
			M.dump_table(v, indent + 2)
		else
			print(string.rep(" ", indent + 2) .. tostring(v))
		end
	end
end

return M
