local function on_select(items, opts, on_choice)
	local lines = {}
	local format = opts.format_item or tostring
	for idx, item in ipairs(items) do
		lines[#lines + 1] = tostring(idx) .. ": " .. format(item)
	end
	lines[#lines + 1] = " "

	local width = 0
	for _, line in ipairs(lines) do
		width = math.max(width, #line)
	end
	width = math.max(width, #opts.prompt)

	local buf = vim.api.nvim_create_buf(false, true)
	local win_config = {
		relative = "editor",
		width = width,
		height = #lines + 1,
		row = 13,
		col = 50,
		style = "minimal",
		border = "rounded",
	}

	local win = vim.api.nvim_open_win(buf, true, win_config)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	vim.bo[buf].buftype = "prompt"
	vim.fn.prompt_setprompt(buf, opts.prompt)

	vim.api.nvim_win_set_option(win, "winhighlight", "Normal:@type,FloatBorder:@type")

	vim.fn.prompt_setcallback(buf, function(text)
		local idx = tonumber(text)
		if idx == nil then
			on_choice(nil, nil)
			vim.api.nvim_win_close(win, false)
			return
		end
		on_choice(items[idx], idx)
		vim.api.nvim_win_close(win, false)
	end)

	vim.keymap.set("n", "<esc>", function()
		vim.api.nvim_win_close(0, false)
		on_choice(nil, nil)
	end, { buffer = buf })

	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(0, false)
		on_choice(nil, nil)
	end, { buffer = buf })

	vim.cmd("startinsert!")
end

vim.ui.select = on_select
