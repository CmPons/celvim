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

local function create_confirm_window(msg)
	-- Clean up the message text
	msg = msg:gsub("^%s*(.-)%s*$", "%1") -- trim
	msg = msg:gsub("\n+$", "") -- remove trailing newlines

	local lines = vim.split(msg, "\n", { plain = true })

	-- Calculate dimensions
	local width = 0
	for _, line in ipairs(lines) do
		width = math.max(width, #line)
	end
	width = math.min(60, math.max(30, width))

	-- Create buffer and window
	local buf = vim.api.nvim_create_buf(false, true)
	local win_config = {
		relative = "editor",
		width = width,
		height = #lines,
		row = math.floor((vim.o.lines - #lines) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = " Confirm ",
	}

	local win = vim.api.nvim_open_win(buf, true, win_config)

	-- Set content
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Set window options
	vim.api.nvim_win_set_option(win, "winhighlight", "Normal:Normal,FloatBorder:FloatBorder")

	-- Set keymaps
	local function close_and_respond(response)
		if vim.api.nvim_buf_is_valid(buf) then
			vim.api.nvim_buf_delete(buf, { force = true })
		end

		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end

		vim.api.nvim_input(response)
	end

	-- Set up key mappings for the buffer
	vim.keymap.set("n", "y", function()
		close_and_respond("y")
	end, { buffer = buf, nowait = true })
	vim.keymap.set("n", "Y", function()
		close_and_respond("y")
	end, { buffer = buf, nowait = true })
	vim.keymap.set("n", "n", function()
		close_and_respond("n")
	end, { buffer = buf, nowait = true })
	vim.keymap.set("n", "N", function()
		close_and_respond("n")
	end, { buffer = buf, nowait = true })
	vim.keymap.set("n", "<esc>", function()
		close_and_respond("n")
	end, { buffer = buf, nowait = true })
	vim.keymap.set("n", "q", function()
		close_and_respond("n")
	end, { buffer = buf, nowait = true })

	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

	return buf, win
end

-- Note. Cannot use vim.schedule here because the input won't work
---@type fun(event: string, ...): boolean
local function callback(event, ...)
	if event == "msg_show" then
		local kind, content, replace_last, history = ...
		print("Recv msg", vim.inspect(kind), vim.inspect(content))
		local text = get_message_text(content)

		if critical_errors[kind] then
			vim.notify(text, vim.log.levels.ERROR)
		elseif kind == "return_prompt" then
			vim.api.nvim_input("<cr>")

			return true
		elseif kind == "confirm" then
			vim.schedule(function()
				create_confirm_window(text)
			end)
		else
			print(text)
		end
		return true
	elseif event == "msg_clear" or "msg_showmode" or "msg_ruler" then
		return true
	elseif event == "msg_history_show" then
		vim.cmd.Logs()
		vim.api.nvim_input("<cr>")
		return true
	elseif event == "msg_history_clear" then
		vim.cmd.ClearLogs()
		return true
	end

	return false
end

vim.ui_attach(ns, {
	ext_messages = true,
}, callback)

vim.api.nvim_create_user_command("Nil", function()
	x.bad()
end, {})
