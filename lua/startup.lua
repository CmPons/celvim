vim.cmd("colorscheme nord")

local f = [[
 ██████╗███████╗██╗         ██╗   ██╗██╗███╗   ███╗
██╔════╝██╔════╝██║         ██║   ██║██║████╗ ████║
██║     █████╗  ██║         ██║   ██║██║██╔████╔██║
██║     ██╔══╝  ██║         ╚██╗ ██╔╝██║██║╚██╔╝██║
╚██████╗███████╗███████╗     ╚████╔╝ ██║██║ ╚═╝ ██║
 ╚═════╝╚══════╝╚══════╝      ╚═══╝  ╚═╝╚═╝     ╚═╝
]]

local function PrependMargin(margin, text)
	for _ = 1, margin, 1 do
		text = " " .. text
	end

	return text
end

local function InsertToBuf(margin, text, buf, start_line)
	for i = 1, #text do
		local line = text[i]
		text[i] = PrependMargin(margin, line)
	end

	vim.api.nvim_buf_set_lines(buf, start_line, -1, false, text)
end

local window_size = { width = vim.o.columns, height = vim.o.lines }

local title = vim.split(f, "\n")

local buf = vim.api.nvim_create_buf(false, true)

local title_margin = 50
InsertToBuf(title_margin, title, buf, 0)

local art = require("art").GetRandArt()
InsertToBuf(art.margin, art.text, buf, 7)

vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
vim.api.nvim_set_current_buf(buf)

local win = vim.api.nvim_open_win(
	buf,
	true,
	{ relative = "editor", row = 0, col = 0, width = window_size.width, height = window_size.height }
)
vim.api.nvim_win_set_buf(win, buf)
