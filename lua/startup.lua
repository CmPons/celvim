local M = {}
M.initialized = false
M.title_margin = 50
M.title = [[
 ██████╗███████╗██╗         ██╗   ██╗██╗███╗   ███╗
██╔════╝██╔════╝██║         ██║   ██║██║████╗ ████║
██║     █████╗  ██║         ██║   ██║██║██╔████╔██║
██║     ██╔══╝  ██║         ╚██╗ ██╔╝██║██║╚██╔╝██║
╚██████╗███████╗███████╗     ╚████╔╝ ██║██║ ╚═╝ ██║
 ╚═════╝╚══════╝╚══════╝      ╚═══╝  ╚═╝╚═╝     ╚═╝
]]

function M.ClearBuffer(buf)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
end

function M.PrependMargin(margin, text)
	for _ = 1, margin, 1 do
		text = " " .. text
	end

	return text
end

function M.InsertToBuf(margin, text, buf, start_line)
	for i = 1, #text do
		local line = text[i]
		text[i] = M.PrependMargin(margin, line)
	end

	vim.api.nvim_buf_set_lines(buf, start_line, -1, false, text)
end

function M.Init()
	vim.cmd("colorscheme nord")
	vim.o.ruler = false

	local window_size = { width = vim.o.columns, height = vim.o.lines }
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, "Startup")

	M.buf = buf

	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })

	M.ClearBuffer(buf)

	local title = vim.split(M.title, "\n")
	M.InsertToBuf(M.title_margin, title, buf, 0)

	local art = require("startup.art").GetRandArt()
	M.InsertToBuf(art.margin, art.text, buf, 7)

	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	vim.api.nvim_set_current_buf(buf)

	-- local win = vim.api.nvim_open_win(
	-- 	buf,
	-- 	true,
	-- 	{ relative = "editor", row = 0, col = 0, width = window_size.width, height = window_size.height }
	-- )
	-- vim.api.nvim_win_set_buf(win, buf)
end

function M.Cleanup()
	if M.buf ~= nil then
		vim.api.nvim_buf_delete(M.buf, {})
	end
end

return M
