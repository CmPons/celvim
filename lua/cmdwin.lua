vim.o.cmdheight = 0

local cmdline_win = nil
local cmdline_buf = nil
local cmd_ns = vim.api.nvim_create_namespace("cmd_ns")

local configs = {
	[":"] = { title = "cmd", color = "@type" },
	["/"] = { title = "search", color = "@string" },
	["?"] = { title = "search", color = "@number" },
}

vim.keymap.set("n", "q:", ":", { nowait = true })

vim.ui_attach(cmd_ns, {
	ext_cmdline = true,
}, function(event, kind, ...)
	local args = { ... }
	local msg = {
		fast = vim.in_fast_event(),
		e = event or "none",
		k = kind or "none",
		args = args,
	}

	print(vim.inspect(msg))

	if event == "cmdline_show" then
		local cursor_pos, firstc, prompt, indent, level, hl_id = ...

		local config = configs[firstc] or { title = "cmd", color = "@string" }

		local contents = kind[1][2]
		if cmdline_win == nil then
			cmdline_buf = vim.api.nvim_create_buf(false, true)
			cmdline_win = vim.api.nvim_open_win(cmdline_buf, true, {
				relative = "editor",
				row = 10,
				col = 50,
				width = 50,
				height = 1,
				style = "minimal",
				border = "rounded",
				title = #prompt > 0 and prompt or config.title,
			})
			vim.fn.setwinvar(
				cmdline_win,
				"&winhl",
				"Normal:" .. config.color .. ",FloatBorder:" .. config.color .. ",FloatTitle:" .. config.color
			)
			vim.api.nvim__redraw({ cursor = true, flush = true, win = cmdline_win })
		end

		if
			cmdline_buf
			and cmdline_win
			and vim.api.nvim_buf_is_valid(cmdline_buf)
			and vim.api.nvim_win_is_valid(cmdline_win)
		then
			local cmdline_contents = firstc .. string.rep(" ", indent) .. contents .. " "
			vim.api.nvim_buf_set_lines(cmdline_buf, 0, -1, false, { cmdline_contents })
			vim.api.nvim_win_set_cursor(cmdline_win, { vim.api.nvim_buf_line_count(cmdline_buf), #cmdline_contents })
			vim.api.nvim__redraw({ cursor = true, flush = true, win = cmdline_win })
		end

		return true
	elseif event == "cmdline_hide" then
		if cmdline_win ~= nil then
			if not vim.api.nvim_win_is_valid(cmdline_win) then
				return
			end

			vim.api.nvim_win_close(cmdline_win, true)
			cmdline_win = nil
			cmdline_buf = nil
		end
		return true
	end

	return false
end)
