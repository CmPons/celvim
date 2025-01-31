local popup = {
	win = nil,
	buf = nil,
	ns = vim.api.nvim_create_namespace("popup_ns"),
	items = nil,
	current_pos = { row = nil, col = nil },
	config = {
		default_row = 0.47,
		default_col = 0.35,
		default_width = 10,
		max_height = 10,
	},
}

local kind_icons = {
	Text = "󰀬",
	Function = "󰊕",
	Method = "󰆧",
	Constructor = "󰒓",
	Field = "󰜢",
	Variable = "󰀫",
	Class = "󰠱",
	Interface = "󰕘",
	Module = "󰏗",
	Property = "󰜢",
	Unit = "󰑭",
	Value = "󰎠",
	Enum = "󰒻",
	Keyword = "󰌋",
	Snippet = "󰩫",
	Color = "󰏘",
	File = "󰈙",
	Reference = "󰈇",
	Folder = "󰉋",
	EnumMember = "󰒻",
	Constant = "󰏿",
	Struct = "󰙅",
	Event = "󰉒",
	Operator = "󰆕",
	TypeParameter = "󰊄",
	Table = "󰓫",
	Object = "󰅩",
	Tag = "󰓹",
	Array = "󰅪",
	Boolean = "󰨙",
	Number = "󰎠",
	String = "󰀬",
	Null = "󰟢",
}

local function convert_index(zero_based_index)
	return zero_based_index + 1
end

local function get_window_position(row, col)
	local m = vim.api.nvim_get_mode().mode
	-- In command mode, use the default
	if m == "c" or m == "cv" or m == "ce" then
		local utils = require("utils")
		local pos = utils.pos_from_screen_percent({ row = popup.config.default_row, col = popup.config.default_col })
		return pos.row, pos.col
	end

	-- Check if we should render the popup above
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local height = #popup.items < popup.config.max_height and #popup.items or popup.config.max_height
	local render_above = (#lines - cursor_pos[1]) < height

	if render_above then
		-- -2 for the border
		row = row - height - 2
		return row, col
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

	local longest_word = 0
	local longest_kind = 0

	for i = start_idx, end_idx do
		local item = items[i]
		if item ~= nil then
			local word, kind = item[1], item[2]

			if #word > longest_word then
				longest_word = #word
			end

			if #kind > longest_kind then
				longest_kind = #kind
			end
		end
	end

	local spans = {}
	for i = start_idx, end_idx do
		local item = items[i]
		if item ~= nil then
			local word, kind, menu = item[1], item[2], item[3]

			local word_spaces = longest_word - #word

			local line = word
			line = line .. string.rep(" ", word_spaces) .. " "

			local kind_start = vim.fn.strdisplaywidth(line)
			local icon = kind_icons[kind] and kind_icons[kind] or ""
			if kind_icons[kind] == nil then
				warn("Missing icon for " .. kind)
			end

			line = line .. icon .. " " .. kind .. " "

			local kind_spaces = longest_kind - #kind
			line = line .. string.rep(" ", kind_spaces)

			local menu_start = #line

			if menu and menu ~= "" then
				line = line .. menu .. " "
			end

			local span = {
				word = { start = 0, len = #word },
				kind = { start = kind_start, len = vim.fn.strdisplaywidth(kind) + 6 },
				menu = { start = menu_start, len = menu and #menu or 0 },
			}

			lines[#lines + 1] = line
			spans[#spans + 1] = span
			width = math.max(width, #line)
		end
	end

	return lines, width, spans
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
		border = "single",
	})

	vim.api.nvim_win_set_option(win, "winhighlight", "FloatBorder:Identifier")

	return buf, win
end

local function update_window_content(buf, win, lines, spans, row, col, height, width)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	for i, span in ipairs(spans) do
		vim.api.nvim_buf_add_highlight(
			buf,
			popup.ns,
			"Identifier",
			i - 1,
			span.word.start,
			span.word.start + span.word.len
		)
		vim.api.nvim_buf_add_highlight(buf, popup.ns, "Float", i - 1, span.kind.start, span.kind.start + span.kind.len)

		if span.menu.len ~= 0 then
			vim.api.nvim_buf_add_highlight(
				buf,
				popup.ns,
				"Title",
				i - 1,
				span.menu.start,
				span.menu.start + span.menu.len
			)
		end
	end

	local config = vim.api.nvim_win_get_config(win)
	config.row = row
	config.col = col
	config.height = height
	config.width = width

	vim.api.nvim_win_set_config(win, config)
end

local function update_popup(items, selected, row, col)
	local height = math.min(popup.config.max_height, #items)
	local lines, width, spans = get_visible_items(items, selected, height)
	row, col = get_window_position(row, col)

	if not popup.win then
		popup.buf, popup.win = create_popup_window(row, col, width, height)
	end

	if popup.win and vim.api.nvim_win_is_valid(popup.win) then
		update_window_content(popup.buf, popup.win, lines, spans, row, col, height, width)
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

local function on_popup_hide(_)
	if popup.win and vim.api.nvim_win_is_valid(popup.win) then
		vim.api.nvim_win_close(popup.win, true)
		popup.win = nil
		popup.buf = nil
	end
end

---@type fun(event: string, ...): boolean
local function callback(event, ...)
	-- Note, we use vim.schedule here because for some reason script errors aren't reported in ui_attach!
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
end

vim.ui_attach(popup.ns, {
	ext_popupmenu = true,
}, callback)
