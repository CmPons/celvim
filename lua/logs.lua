local M = {}
M.log_lines = {}
M.pending_notifications = {}
M.shown_notifications = {}
M.notification_timer = nil

local StartCol = 155
local StartRow = 33
local Spacing = 3
local Height = 1
local MaxWidth = 50
local MinWidth = 8

local log_level_names = {
	[vim.log.levels.DEBUG] = "debug",
	[vim.log.levels.INFO] = "info",
	[vim.log.levels.TRACE] = "trace",
	[vim.log.levels.WARN] = "warning",
	[vim.log.levels.ERROR] = "error",
}

local log_level_icons = {
	[vim.log.levels.DEBUG] = "",
	[vim.log.levels.INFO] = "",
	[vim.log.levels.TRACE] = "",
	[vim.log.levels.WARN] = "",
	[vim.log.levels.ERROR] = "",
}

local log_level_colors = {
	[vim.log.levels.DEBUG] = "DiagnosticSignHint",
	[vim.log.levels.INFO] = "@string",
	[vim.log.levels.TRACE] = "DiagnosticSignHint",
	[vim.log.levels.WARN] = "NotifyWARNBorder",
	[vim.log.levels.ERROR] = "DiagnosticSignError",
}

local DefaultHighlight = "DiagnosticSignHint"

M.create_notification_win = function(msg, row, level)
	local icon = log_level_icons[level]
	if icon == nil then
		icon = "!"
	end

	local buf = vim.api.nvim_create_buf(false, true)
	local lines = vim.split(msg, "\n", { plain = true })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	local width = 0
	for _, line in ipairs(lines) do
		if #line > width then
			width = #line
		end
	end

	if width > MaxWidth and not level == vim.log.levels.ERROR then
		width = MaxWidth
	end
	if width < MinWidth then
		width = MinWidth
	end

	local config = {
		relative = "editor",
		row = row,
		col = StartCol,
		width = width,
		height = Height,
		anchor = "SE",
		border = "rounded",
		style = "minimal",
		title = icon,
	}

	local win = vim.api.nvim_open_win(buf, false, config)

	local highlight = log_level_colors[level] or DefaultHighlight
	vim.fn.setwinvar(win, "&winhl", "Normal:" .. highlight .. ",FloatBorder:" .. highlight)

	return win
end

M.find_existing_notif = function(msg)
	for _, notif in ipairs(M.shown_notifications) do
		if notif.msg == msg then
			return notif
		end
	end

	return nil
end

M.update_notifications = function()
	for _, notif in ipairs(M.pending_notifications) do
		local existing_notif = M.find_existing_notif(notif.msg)
		if existing_notif ~= nil then
			-- Keep it alive
			existing_notif.start = os.time()
		else
			local win = M.create_notification_win(notif.msg, StartRow, notif.level)
			notif.win = win
			M.shown_notifications[#M.shown_notifications + 1] = notif
		end
	end

	M.pending_notifications = {}

	-- Update positions
	for i, notif in ipairs(M.shown_notifications) do
		local zero_idx = i - 1
		local row = StartRow - (zero_idx * Spacing)
		if vim.api.nvim_win_is_valid(notif.win) then
			local config = vim.api.nvim_win_get_config(notif.win)
			config.row = row
			vim.api.nvim_win_set_config(notif.win, config)
		end
	end

	local now = os.time()
	for i = #M.shown_notifications, 1, -1 do
		local notif = M.shown_notifications[i]
		if now - notif.start > 5 then
			table.remove(M.shown_notifications, i)
			if vim.api.nvim_win_is_valid(notif.win) then
				local buf = vim.api.nvim_win_get_buf(notif.win)
				pcall(vim.api.nvim_buf_delete, buf, { force = false })
			end
		end
	end
end

M.Init = function()
	vim.api.nvim_create_user_command("ClearLogs", function()
		M.log_lines = {}
	end, {})

	vim.api.nvim_create_user_command("Logs", function()
		local buf = vim.api.nvim_create_buf(false, true)
		pcall(vim.api.nvim_buf_set_name, buf, "Logs")
		local config = {
			relative = "editor",
			row = 2,
			col = 2,
			width = 140,
			height = 40,
			border = "single",
			style = "minimal",
			title = "Log",
		}
		local win = vim.api.nvim_open_win(buf, true, config)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, M.log_lines)

		if #M.log_lines ~= 0 then
			vim.api.nvim_win_set_cursor(win, { #M.log_lines, 0 })
		end

		vim.keymap.set("n", "q", function()
			if win ~= nil and vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
				win = nil
			end
		end, { buffer = M.log_buf, nowait = true })

		vim.keymap.set("n", "<esc>", function()
			if win ~= nil and vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
				win = nil
			end
		end, { buffer = M.log_buf, nowait = true })
	end, {})

	vim.keymap.set("n", "<leader>l", ":Logs<enter>", { desc = "Open the logs window" })

	local timer = vim.loop.new_timer()
	timer:start(
		1000,
		1000,
		vim.schedule_wrap(function()
			M.update_notifications()
		end)
	)
	M.notification_timer = timer
end

M.format_log_msg = function(msg, level)
	local util = require("utils")
	local log_name = log_level_names[level] or tostring(level)
	return "[" .. util.get_curr_date_time() .. "] - " .. log_name .. " - " .. msg
end

M.push_log_msg = function(msg)
	M.log_lines[#M.log_lines + 1] = msg
end

function LogMsg(msg, level, _)
	local log_level = level or vim.log.levels.INFO

	local msg_lines = vim.split(msg, "\n")
	for _, line in ipairs(msg_lines) do
		local log_msg = M.format_log_msg(line, log_level)
		M.push_log_msg(log_msg)
	end

	if log_level ~= vim.log.levels.DEBUG then
		M.pending_notifications[#M.pending_notifications + 1] =
			{ start = os.time(), msg = msg, level = log_level, win = nil }
	end
end

vim.notify = LogMsg
print = function(...)
	local print_safe_args = {}
	local _ = { ... }
	for i = 1, #_ do
		table.insert(print_safe_args, tostring(_[i]))
	end

	local msg = table.concat(print_safe_args, " ")
	vim.notify(msg, vim.log.levels.DEBUG)
end

return M
