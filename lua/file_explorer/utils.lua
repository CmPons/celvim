M = {}
function M.GetFilesInPath(dir)
	local files = vim.system({ "find", dir, "-maxdepth", "1", "-type", "f" }, { text = true }):wait()
	files = vim.split(files.stdout, "\n")
	return files
end

function M.GetDirectoriesInPath(dir)
	local files = vim.system({ "find", dir, "-maxdepth", "1", "-type", "d" }, { text = true }):wait()
	files = vim.split(files.stdout, "\n")
	return files
end

function M.BuildDisplayName(path, file_type)
	local split_path = vim.split(path, "/")
	if #split_path == 1 or path == "" then
		return path
	end

	local display_name = split_path[#split_path]

	if file_type == "Directory" then
		display_name = display_name .. "/"
	end

	return display_name
end

function M.FindVisibleChild(root, place)
	if place == 0 and root.visible then
		return root
	end

	for _, child in ipairs(root.children) do
		if not child.visible then
			goto continue
		end

		place = place - 1
		if place == 0 then
			return child
		else
			M.FindVisibleChild(child, place)
		end

		::continue::
	end

	return nil
end

function M.PrintStates(root)
	print("Name: " .. root.display_name .. " visible " .. tostring(root.visible))

	for _, child in ipairs(root.children) do
		print("Name: " .. child.display_name .. " visible " .. tostring(child.visible))
		M.PrintStates(child)
	end
end

return M
