local popup = {
	win = nil,
	buf = nil,
	ns = vim.api.nvim_create_namespace("popup_ns"),
	items = nil,
	current_pos = { row = nil, col = nil },
	config = {
		default_row = 12,
		default_col = 51,
		default_width = 10,
		max_height = 10,
	},
}

local function convert_index(zero_based_index)
	return zero_based_index + 1
end

local function get_window_position(row, col)
	if row == 0 and col == 0 then
		return popup.config.default_row, popup.config.default_col
	end
	return row + 1, col
end

local function get_visible_items(items, selected, height)
	local lua_index = convert_index(selected)
	local start_idx = lua_index
	local end_idx = start_idx + height
	if end_idx > #items then
		end_idx = #items
	end

	local lines = {}
	local width = popup.config.default_width
	for i = start_idx, end_idx do
		local item = items[i]
		if item ~= nil then
			local word = item[1]
			lines[#lines + 1] = word
			width = math.max(width, #word)
		end
	end

	return lines, width
end

local function create_popup_window(row, col, width, height)
	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, false, {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = height,
		style = "minimal",
		border = "none",
	})

	vim.fn.setwinvar(win, "&winhl", "Normal:ColorColumn")

	return buf, win
end

local function update_window_content(buf, win, lines, row, col, height)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	local config = vim.api.nvim_win_get_config(win)
	config.row = row
	config.col = col
	config.height = height
	config.width = math.max(popup.config.default_width, #lines[1] or 0)

	vim.api.nvim_win_set_config(win, config)
	vim.api.nvim_buf_add_highlight(buf, -1, "illuminatedWord", 0, 0, -1)
end

local function update_popup(items, selected, row, col)
	local height = math.min(popup.config.max_height, #items)
	local lines, width = get_visible_items(items, selected, height)
	row, col = get_window_position(row, col)

	if not popup.win then
		popup.buf, popup.win = create_popup_window(row, col, width, height)
	end

	if popup.win and vim.api.nvim_win_is_valid(popup.win) then
		update_window_content(popup.buf, popup.win, lines, row, col, height)
	end
end

local function on_popup_show(items, selected, row, col, _)
	if #items == 0 then
		return
	end
	popup.items = items
	popup.current_pos = { row = row, col = col }
	selected = selected == -1 and 0 or selected
	update_popup(items, selected, row, col)
end

local function on_popup_selected(selected)
	if not popup.win or not popup.buf or not popup.items or selected < 0 then
		return
	end
	update_popup(popup.items, selected, popup.current_pos.row, popup.current_pos.col)
end

local function on_popup_hide()
	if popup.win and vim.api.nvim_win_is_valid(popup.win) then
		vim.api.nvim_win_close(popup.win, true)
		popup.win = nil
		popup.buf = nil
	end
end

-- Note, we use vim.schedule here because for some reason script errors aren't reported in ui_attach!
vim.ui_attach(popup.ns, {
	ext_popupmenu = true,
}, function(event, ...)
	if event == "popupmenu_show" then
		local items, selected, row, col, grid = ...
		vim.schedule(function()
			on_popup_show(items, selected, row, col, grid)
		end)
		return true
	elseif event == "popupmenu_hide" then
		local selected = ...
		vim.schedule(function()
			on_popup_hide(selected)
		end)
		return true
	elseif event == "popupmenu_select" then
		local selected = ...
		vim.schedule(function()
			on_popup_selected(selected)
		end)
		return true
	end
	return false
end)
