local ns = vim.api.nvim_create_namespace("message_handler")

local function get_message_text(content)
	local text = ""
	for _, chunk in ipairs(content) do
		-- chunk format: [attr_id, text_chunk, hl_id]
		text = text .. chunk[2]
	end
	return text
end

local critical_errors = {
	emsg = true,
	lua_error = true,
	rpc_error = true,
	echoerr = true,
}
local confirm_win = nil
local confirm_buf = nil

local confirm_win_type = {
	YES_NO = 1,
	CODE_ACTION = 2,
}

local function confirm_win_valid()
	return confirm_win ~= nil and confirm_buf ~= nil
end

local function clear_confirm_win()
	if confirm_win and vim.api.nvim_win_is_valid(confirm_win) then
		vim.api.nvim_win_close(confirm_win, false)
	end

	if confirm_buf and vim.api.nvim_buf_is_valid(confirm_buf) then
		vim.api.nvim_buf_delete(confirm_buf, { force = false })
	end

	confirm_win = nil
	confirm_buf = nil
end

local function create_confirm_window(msg, title, win_type)
	local lines = vim.split(msg, "\n", { plain = true, trimempty = true })

	if win_type == confirm_win_type.CODE_ACTION then
		table.remove(lines, 1)
		table.remove(lines, #lines)
	end

	local width = 0
	for _, line in ipairs(lines) do
		width = math.max(width, #line)
	end
	width = math.min(60, math.max(30, width))

	local buf = vim.api.nvim_create_buf(false, true)
	local win_config = {
		relative = "editor",
		width = width,
		height = #lines,
		row = math.floor((vim.o.lines - #lines) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = title,
	}

	local win = vim.api.nvim_open_win(buf, true, win_config)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	vim.api.nvim_win_set_option(win, "winhighlight", "Normal:Normal,FloatBorder:FloatBorder")
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	if win_type == confirm_win_type.CODE_ACTION then
		vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
			buffer = buf,
			callback = clear_confirm_win,
			once = true,
		})
	end

	-- Force a redraw. This seems to need to be done if we're in command mode
	vim.api.nvim__redraw({ cursor = true, win = win, flush = true })

	return buf, win
end

-- Note! Cannot use vim.schedule here because then input won't work
---@type fun(event: string, ...): boolean
local function callback(event, ...)
	if event == "msg_show" then
		local kind, content, replace_last, history = ...
		local text = get_message_text(content)

		if critical_errors[kind] then
			vim.notify(text, vim.log.levels.ERROR)
		elseif kind == "list_cmd" then
			confirm_buf, confirm_win = create_confirm_window(text, "")
		elseif kind == "return_prompt" then
			vim.api.nvim_input("<cr>")
			return true
		elseif kind == "confirm" then
			confirm_buf, confirm_win = create_confirm_window(text, "Confirm", confirm_win_type.YES_NO)
		else
			if text:find("Code actions:") then
				confirm_buf, confirm_win = create_confirm_window(text, "Code Actions:", confirm_win_type.CODE_ACTION)
			else
				print(text)
			end
		end
		return true
	elseif event == "msg_clear" then
		if confirm_win_valid() then
			clear_confirm_win()
		end
		return true
	elseif event == "msg_history_show" then
		vim.cmd.Logs()
		vim.api.nvim_input("<cr>")
		return true
	elseif event == "msg_history_clear" then
		vim.cmd.ClearLogs()
		return true
	elseif event == "msg_showmode" or event == "msg_ruler" then
		return true
	end

	return false
end

vim.ui_attach(ns, {
	ext_messages = true,
}, callback)

vim.api.nvim_create_user_command("TestErrors", function()
	x.bad()
end, {})
