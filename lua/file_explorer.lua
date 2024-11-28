local utils = require("file_explorer.utils")

local file_tree = { path = ".", children = {}, display_name = "." }

local function on_select_line()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local cursor_line = cursor_pos[1]
	local selected_node = utils.FindVisibleChild(file_tree, cursor_line - 1)

	if selected_node ~= nil and #selected_node.children > 0 then
		print("Selected ", selected_node.path)
		for _, child in ipairs(selected_node.children) do
			child.visible = not child.visible
			print("Setting child visible: ", tostring(child.visible) .. " " .. child.display_name)
		end
	end

	WriteFileTreeToBuf(0, file_tree)

	vim.api.nvim_win_set_cursor(0, cursor_pos)
end

vim.api.nvim_create_user_command("FileExplorer", function()
	local buf = vim.api.nvim_create_buf(true, true)

	local config = {
		relative = "editor",
		row = 10,
		col = 10,
		width = 100,
		height = 400,
		border = "single",
		style = "minimal",
		title = "Files",
	}
	vim.api.nvim_open_win(buf, true, config)

	file_tree = BuildFileTree()

	WriteFileTreeToBuf(buf, file_tree)

	vim.keymap.set("n", "<enter>", function()
		on_select_line()
	end, { buffer = buf })
end, { desc = "Open the file explorer" })

function WriteFileTreeToBuf(buf, tree_root)
	utils.PrintStates(tree_root)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
	local line_num = 0

	vim.api.nvim_buf_set_lines(buf, line_num, line_num, false, { tree_root.display_name })
	line_num = line_num + 1

	WriteFileTreeToBufRecursive(buf, tree_root, line_num)
end

function WriteFileTreeToBufRecursive(buf, root, line_num)
	for _, child in ipairs(root.children) do
		if child.visible then
			print("Writing " .. child.display_name .. " to line " .. line_num)
			vim.api.nvim_buf_set_lines(buf, line_num, line_num, false, { child.display_name })
			line_num = line_num + 1

			line_num = WriteFileTreeToBufRecursive(buf, child, line_num)
		end
	end

	return line_num
end

function BuildFileTree()
	local root = { path = ".", children = {}, display_name = "." }
	local curr_path = "."

	local child_files = utils.GetFilesInPath(curr_path)
	for _, path in ipairs(child_files) do
		if path == "" then
			goto continue
		end

		local display_name = utils.BuildDisplayName(path, "File")

		local file = { type = "File", path, display_name = display_name, visible = true, children = {} }
		table.insert(root.children, file)

		::continue::
	end

	local child_directories = utils.GetDirectoriesInPath(curr_path)
	for _, path in ipairs(child_directories) do
		if path == "" or path == "." then
			goto continue
		end

		local directory = BuildFileTreeRecursive(path)
		if directory ~= nil then
			table.insert(root.children, directory)
		end

		::continue::
	end

	for _, child in ipairs(root.children) do
		child.visible = true
	end

	return root
end

function BuildFileTreeRecursive(dir)
	if dir == "" then
		return
	end

	local curr_path = dir
	local root_name = utils.BuildDisplayName(dir, "Directory")
	local root = { type = "Directory", path = dir, children = {}, display_name = root_name, visible = false }

	local child_files = utils.GetFilesInPath(curr_path)
	for _, path in ipairs(child_files) do
		if path == "" then
			goto continue
		end

		local file_display_name = utils.BuildDisplayName(path, "File")

		local file = { type = "File", path, display_name = file_display_name, visible = false, children = {} }
		table.insert(root.children, file)
		::continue::
	end

	local child_directories = utils.GetDirectoriesInPath(curr_path)
	for _, path in ipairs(child_directories) do
		if path == "" or "." then
			goto continue
		end

		local directory = BuildFileTreeRecursive(path)
		if directory ~= nil then
			table.insert(root.children, directory)
		end

		::continue::
	end

	return root
end

-- 	line_no_start = [[└── ]] .. line_no_start
-- else
-- 	line_no_start = [[├── ]] .. line_no_start

vim.keymap.set("n", "<Leader>f", "", { desc = "Files" })
vim.keymap.set("n", "<Leader>fe", function()
	vim.cmd("FileExplorer")
end, {})
