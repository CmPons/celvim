local utils = require("file_explorer.utils")

local file_tree = { path = ".", children = {}, display_name = "." }

local function on_select_line()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local cursor_line = cursor_pos[1]

	vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
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

	vim.keymap.set("n", "<leader>fe", function()
		vim.api.nvim_win_close(0, true)
	end, { buffer = buf })
end, { desc = "Open the file explorer" })

function WriteFileTreeToBuf(buf, tree_root)
	local line_num = 0
	for _, file in ipairs(tree_root) do
		if file.visible then
			local _, indent = string.gsub(file.path, "/", "")

			local line = ""
			if indent > 1 then
				for _ = 1, indent do
					line = "  " .. line
				end
			end

			line = line .. file.display_name

			if file.type == "Directory" then
				line = [[ ]] .. line
			end

			vim.api.nvim_buf_set_lines(buf, line_num, line_num, false, { line })
			line_num = line_num + 1
		end
	end
end

function BuildFileTree()
	local file_strs = utils.GetFilesInPath(".")
	local parsed_files = {}

	for i, file in ipairs(file_strs) do
		local path = file
		local f = string.sub(file, 3)
		file = f

		local type = "File"
		if vim.fn.isdirectory(path) ~= 0 then
			type = "Directory"
		end

		local visible = true
		local _, depth = file:gsub("/", "")
		if depth > 0 then
			visible = false
		end

		local display_name = utils.BuildDisplayName(path, type == "Directory")

		local file_table = { visible = visible, path = path, type = type, display_name = display_name }

		table.insert(parsed_files, file_table)
	end

	return parsed_files
end

vim.keymap.set("n", "<Leader>f", "", { desc = "Files" })
vim.keymap.set("n", "<Leader>fe", function()
	vim.cmd("FileExplorer")
end, {})
