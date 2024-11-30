local utils = require("file_explorer.utils")

local root_path = "."
local file_tree = {}
local cursor_pos_save = {}

local function refresh_file_view(new_path)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
	file_tree = {}

	root_path = new_path
	file_tree = BuildFileTree(new_path)
	WriteFileTreeToBuf(0, file_tree)

	local saved_pos = cursor_pos_save[new_path] or { 1, 1 }

	vim.api.nvim_win_set_cursor(0, saved_pos)
end

local function on_select_line()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local cursor_line = cursor_pos[1]
	cursor_pos_save[root_path] = cursor_pos

	local file_item = file_tree[cursor_line]
	if file_item == nil then
		return
	end

	print("Selected .. " .. file_item.display_name .. " at " .. file_item.path)

	if file_item.type == "File" then
		vim.api.nvim_win_close(0, true)
		vim.cmd.tabedit(file_item.path)
	else
		refresh_file_view(file_item.path)
	end
end

local function on_go_to_parent()
	if root_path == "." then
		vim.api.nvim_win_close(0, true)
	end

	local last_slash = string.find(root_path, "/[^/]*$")
	if last_slash ~= nil then
		root_path = root_path:sub(0, last_slash - 1)
		refresh_file_view(root_path)
	end
end

vim.api.nvim_create_user_command("FileExplorer", function()
	local buf = vim.api.nvim_create_buf(true, true)

	local config = {
		relative = "editor",
		row = 10,
		col = 50,
		width = 50,
		height = 30,
		border = "single",
		style = "minimal",
		title = "Files",
	}
	vim.api.nvim_open_win(buf, true, config)

	file_tree = BuildFileTree(".")

	WriteFileTreeToBuf(buf, file_tree)
	vim.api.nvim_win_set_cursor(0, { 1, 1 })

	vim.keymap.set("n", "<enter>", function()
		on_select_line()
	end, { buffer = buf })

	vim.keymap.set("n", "<backspace>", function()
		on_go_to_parent()
	end)

	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(0, true)
	end)

	vim.keymap.set("n", "<leader>fe", function()
		vim.api.nvim_win_close(0, true)
	end, { buffer = buf })
end, { desc = "Open the file explorer" })

function WriteFileTreeToBuf(buf, tree_root)
	local line_num = 0
	for _, file in ipairs(tree_root) do
		if file.path ~= root_path then
			local line = ""

			line = line .. file.display_name

			if file.type == "Directory" then
				line = [[ ]] .. line
			else
				local icons = require("file_explorer.icons")
				local extension = utils.GetExtension(file.display_name)

				local icon = icons[extension]
				if icon ~= nil then
					line = icon .. " " .. line
				else
					line = "  " .. line
				end
			end

			vim.api.nvim_buf_set_lines(buf, line_num, line_num, false, { line })
			line_num = line_num + 1
		end
	end
end

function BuildFileTree(path)
	local file_strs = utils.GetFilesInPath(path)

	local parsed_files = {}

	for _, file in ipairs(file_strs) do
		local file_path = file
		local f = string.sub(file, 3)
		file = f

		local type = "File"
		if vim.fn.isdirectory(file_path) ~= 0 then
			type = "Directory"
		end

		local visible = true
		local _, depth = file:gsub("/", "")
		if depth > 0 then
			visible = false
		end

		local display_name = utils.BuildDisplayName(file_path, type == "Directory")

		local file_table = { visible = visible, path = file_path, type = type, display_name = display_name }

		-- Hide the root, we are already in that folder
		if file_path ~= root_path then
			table.insert(parsed_files, file_table)
		end
	end

	return parsed_files
end

vim.keymap.set("n", "<Leader>f", "", { desc = "Files" })
vim.keymap.set("n", "<Leader>fe", function()
	vim.cmd("FileExplorer")
end, {})
