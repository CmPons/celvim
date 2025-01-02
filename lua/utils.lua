local M = {}

M.get_filetype = function(file_name)
	local dot_pos = string.find(file_name, "%.")
	if dot_pos == nil then
		return nil
	end
	local ext = string.sub(file_name, dot_pos + 1, -1)
	return ext
end

return M
