local popup_win = nil
local popup_buf = nil
local popup_ns = vim.api.nvim_create_namespace("popup_ns")

local default_row = 13
local default_col = 50
local default_width = 10
local max_height = 10
local popup_items = nil

local function on_popup_show(items, selected, row, col, _)
	if #items == 0 then
		return
	end

	popup_items = items

	local relative = "editor"
	if row == 0 and col == 0 then
		row = default_row
		col = default_col
	else
		row = row + 1
		col = col
	end

	local width = default_width
	local height = max_height
	if #items < max_height then
		height = #items
	end

	if selected == -1 then
		selected = 1
	end

	local lines = {}
	local start_idx = selected + 1
	local end_idx = start_idx + height
	if end_idx > #items then
		end_idx = #items
	end
	print("Selected " .. selected .. " start " .. start_idx .. " end " .. end_idx)

	for i = start_idx, end_idx do
		local item = items[i]
		if item ~= nil then
			local word = item[1]
			lines[#lines + 1] = word
			width = math.max(width, #word)
		end
	end
	print(vim.inspect(lines), selected)

	if popup_win == nil then
		popup_buf = vim.api.nvim_create_buf(false, true)
		popup_win = vim.api.nvim_open_win(popup_buf, false, {
			relative = relative,
			row = row,
			col = col,
			width = width,
			height = height,
			style = "minimal",
			border = "none",
		})
		vim.api.nvim__redraw({ cursor = true, flush = true, win = popup_win })
	end

	if popup_buf and popup_win and vim.api.nvim_buf_is_valid(popup_buf) and vim.api.nvim_win_is_valid(popup_win) then
		vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, lines)
		local config = vim.api.nvim_win_get_config(popup_win)
		config.row = row
		config.col = col
		config.height = height

		vim.api.nvim_win_set_config(popup_win, config)
		vim.fn.setwinvar(popup_win, "&winhl", "Normal:ColorColumn")
		vim.api.nvim_buf_add_highlight(popup_buf, -1, "illuminatedWord", 0, 0, -1)

		vim.api.nvim__redraw({ cursor = true, flush = true, win = popup_win })
	end
end

local function on_popup_selected(selected)
	if popup_win == nil or popup_buf == nil or popup_items == nil or selected < 0 then
		return
	end

	local height = max_height
	if (#popup_items - selected) < max_height then
		height = #popup_items
	end

	local lines = {}
	local width = 0

	local start_idx = selected + 1
	local end_idx = start_idx + height
	if end_idx > #popup_items then
		end_idx = #popup_items
	end

	print("Selected " .. selected .. " start " .. start_idx .. " end " .. end_idx)
	for i = start_idx, end_idx do
		local item = popup_items[i]
		if item ~= nil then
			local word = popup_items[i][1]
			lines[#lines + 1] = word
			width = math.max(width, #word)
		end
	end

	vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, lines)
	local config = vim.api.nvim_win_get_config(popup_win)
	config.width = width
	config.height = height

	vim.api.nvim_buf_add_highlight(popup_buf, -1, "illuminatedWord", 0, 0, -1)
	vim.api.nvim_win_set_config(popup_win, config)
	vim.api.nvim__redraw({ cursor = true, flush = true, win = popup_win })
end

local function on_popup_hide(selected)
	if popup_win ~= nil then
		if not vim.api.nvim_win_is_valid(popup_win) then
			return
		end

		vim.api.nvim_win_close(popup_win, true)
		popup_win = nil
		popup_buf = nil
	end
end

vim.ui_attach(popup_ns, {
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
