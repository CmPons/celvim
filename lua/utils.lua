local M = {}

M.get_syntax_from_filetype = function(filetype)
	if filetype == "rs" then
		return "rust"
	end

	return filetype
end

M.get_filetype = function(file_name)
	local dot_pos = string.find(file_name, "%.")
	if dot_pos == nil then
		return nil
	end
	local ext = string.sub(file_name, dot_pos + 1, -1)
	return ext
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

return M
