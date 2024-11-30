M = {}
function M.GetFilesInPath(dir)
	local find_result = vim.system({ "find", dir, "-type", "f", "-maxdepth", "1" }, { text = true }):wait()
	local files = vim.system({ "sort" }, { text = true, stdin = find_result.stdout }):wait()

	find_result = vim.system({ "find", dir, "-type", "d", "-maxdepth", "1" }, { text = true }):wait()
	local directories = vim.system({ "sort" }, { text = true, stdin = find_result.stdout }):wait()
	local all_files = vim.split(files.stdout .. directories.stdout, "\n")

	for i = #all_files, 1, -1 do
		local file = all_files[i]
		if file == "." then
			table.remove(all_files, i)
			break
		end
	end

	return all_files
end

function M.BuildDisplayName(path, is_dir)
	local split_path = vim.split(path, "/")
	if #split_path == 1 or path == "" then
		return path
	end

	local display_name = split_path[#split_path]

	if is_dir then
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
	print("Name: " .. root.path .. " visible " .. tostring(root.visible))

	for _, child in ipairs(root.children) do
		print("Name: " .. child.path .. " visible " .. tostring(child.visible))
		M.PrintStates(child)
	end
end

function M.GetExtension(file_name)
	local dot_pos = string.find(file_name, "%.")
	if dot_pos == nil then
		return nil
	end

	local ext = string.sub(file_name, dot_pos + 1, -1)
	return ext
end

return M
