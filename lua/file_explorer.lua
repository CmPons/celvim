M = {}

local closed_folder = ""
local open_folder = ""

local curr_tree = nil
local tree_root_path = ""
local dir_ns = vim.api.nvim_create_namespace("#fe_dir")

local function find_last_dir_idx(contents)
	local last_idx = nil
	for i, tree_node in ipairs(contents) do
		if tree_node.type == "directory" and (last_idx == nil or i > last_idx) then
			last_idx = i
		end
	end
	return last_idx
end

local function traverse_file_tree(file_tree, indent, root_path, in_last_dir, visitor, only_traverse_open)
	only_traverse_open = only_traverse_open or false
	in_last_dir = in_last_dir or false
	indent = indent or 0

	if file_tree == nil then
		return
	end

	if file_tree.name == "." then
		visitor(file_tree, indent, root_path, nil)
	end

	local traverse = only_traverse_open == false
	if only_traverse_open then
		traverse = file_tree.is_open
	end

	if file_tree.contents ~= nil and traverse then
		if file_tree.name ~= "." then
			root_path = root_path .. "/" .. file_tree.name
		end

		indent = indent + 1
		local last_idx = find_last_dir_idx(file_tree.contents)

		for i, v in ipairs(file_tree.contents) do
			visitor(v, indent, root_path, file_tree)

			if v.type == "directory" then
				in_last_dir = (last_idx and last_idx == i) or false
				traverse_file_tree(v, indent, root_path, in_last_dir, visitor, only_traverse_open)
			end
		end
	end
end

local function set_highlights(tree_root, root_path)
	vim.api.nvim_buf_clear_namespace(0, dir_ns, 0, -1)
	traverse_file_tree(tree_root, -1, root_path, false, function(node)
		if node.type ~= "directory" or not node.is_visible then
			return
		end

		vim.api.nvim_buf_add_highlight(0, dir_ns, "Type", node.line - 1, 0, -1)
	end, true)
end

local function render_file_tree(tree_root, root_path)
	local lines = {}
	traverse_file_tree(tree_root, -1, root_path, false, function(node, indent, base_path)
		if node.name == "." then
			lines[#lines + 1] = "  " .. open_folder .. " " .. base_path
			node["line"] = #lines
			return
		end

		local line = "   "

		for _ = 1, indent do
			line = "  " .. line
		end

		local icon = ""
		local icons = require("icons")
		if node.type == "directory" then
			icon = open_folder
			if not node.is_open then
				icon = closed_folder
			end
		elseif node.type == "file" then
			local utils = require("utils")
			local file_type = utils.get_filetype(node.name)
			icon = icons[file_type] or ""
		end

		line = line .. icon .. " " .. node.name

		lines[#lines + 1] = line
		node["line"] = #lines
	end, true)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	set_highlights(tree_root, root_path)
end

local function setup_file_tree(tree_root, root_path)
	traverse_file_tree(tree_root, -1, root_path, false, function(node, level, bash_path, parent)
		local path = ""
		if node.type == "directory" then
			path = bash_path .. "/" .. node.name .. "/"
		else
			path = bash_path .. "/" .. node.name
		end

		if node.name == "." then
			path = bash_path
		end

		node["path"] = path
		node["is_open"] = node.name == "."
		node["is_visible"] = level <= 0
		node["parent"] = parent
	end)
end

local function on_select_line(dir_only, close_parent)
	dir_only = dir_only or false
	close_parent = close_parent or false

	local rerender = false
	local pos = vim.api.nvim_win_get_cursor(0)

	traverse_file_tree(curr_tree, -1, "", false, function(node)
		if node.line ~= pos[1] or not node.is_visible then
			return
		end

		if close_parent and node.parent ~= nil then
			if node.parent.contents ~= nil and #node.parent.contents > 0 then
				node.parent.is_open = false
				vim.api.nvim_win_set_cursor(0, { node.parent.line, 0 })
				for _, child in ipairs(node.parent.contents) do
					child.is_visible = node.parent.is_open
					child.line = -1
				end
			end
			rerender = true
			return
		end

		if node.type == "directory" then
			node.is_open = not node.is_open

			if node.contents ~= nil and #node.contents > 0 then
				for _, child in ipairs(node.contents) do
					child.is_visible = node.is_open
					child.line = -1
				end
			end

			rerender = true
		elseif node.type == "file" and not dir_only then
			local utils = require("utils")

			vim.cmd.tabnew(node.path)

			local filetype = utils.get_filetype(node.path)
			if filetype ~= nil then
				vim.bo.filetype = filetype
				vim.bo.syntax = utils.get_syntax_from_filetype(filetype)
			end
		end
	end)

	if rerender then
		render_file_tree(curr_tree, tree_root_path)
	end
end

local function open_file_explorer()
	if curr_tree == nil then
		local result = vim.system({ "tree", "-J" }):wait()
		if result.code ~= 0 then
			vim.notify("Failed to open file explorer", vim.log.levels.ERROR)
			return
		end

		local file_tree = vim.json.decode(result.stdout)
		local tree_root = file_tree[1]

		local root_path = os.getenv("PWD")
		local home = os.getenv("HOME")
		if root_path == nil or home == nil then
			vim.notify("Failed to open file explorer", vim.log.levels.ERROR)
			return
		end
		root_path = root_path:gsub(home, "~")

		tree_root["path"] = root_path
		tree_root_path = root_path

		setup_file_tree(tree_root, root_path)

		curr_tree = tree_root
	end

	local buf = vim.api.nvim_create_buf(false, true)
	local config = {
		relative = "editor",
		row = 0,
		col = 0,
		width = 60,
		height = 140,
		border = "single",
		style = "minimal",
		title = "File Explorer",
	}
	vim.api.nvim_open_win(buf, true, config)

	render_file_tree(curr_tree, tree_root_path)

	vim.keymap.set("n", "<enter>", function()
		on_select_line()
	end, { buffer = buf })

	vim.keymap.set("n", "h", function()
		on_select_line(true, true)
	end, { buffer = buf })

	vim.keymap.set("n", "l", function()
		on_select_line()
	end, { buffer = buf })

	vim.keymap.set("n", "w", function()
		on_select_line(true)
	end, { buffer = buf })

	-- To prevent creating another when it's already open
	vim.keymap.set("n", "<leader>fe", function() end, {
		buffer = buf,
	})

	vim.keymap.set("n", "q", function()
		vim.api.nvim_buf_delete(0, {})
	end, { buffer = buf })

	vim.api.nvim_create_autocmd({ "BufLeave" }, {
		buffer = buf,
		callback = function()
			pcall(vim.api.nvim_buf_delete, 0, {})
		end,
	})

	local selection_ns = vim.api.nvim_create_namespace("#fe_selection")
	vim.api.nvim_create_autocmd({ "CursorMoved" }, {
		buffer = vim.api.nvim_get_current_buf(),
		callback = function()
			vim.api.nvim_buf_clear_namespace(0, selection_ns, 0, -1)
			local pos = vim.api.nvim_win_get_cursor(0)
			vim.api.nvim_buf_add_highlight(0, selection_ns, "BufferVisible", pos[1] - 1, 0, -1)
		end,
	})
end

M.Init = function()
	vim.keymap.set("n", "<leader>fe", function()
		open_file_explorer()
	end, { desc = "File Explorer" })
end

return M
