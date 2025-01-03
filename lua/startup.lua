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

M.FindBufferByName = function(name)
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local buf_name = vim.api.nvim_buf_get_name(buf)
		if buf_name == name then
			return buf
		end
	end
	return -1
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

	-- If we are reloading the config, don't overwrite
	-- whatever is currently open
	if #vim.api.nvim_list_bufs() == 1 then
		local buf = vim.api.nvim_create_buf(false, true)
		M.buf = buf

		vim.api.nvim_set_option_value("modifiable", true, { buf = buf })

		M.ClearBuffer(buf)

		vim.api.nvim_set_option_value("number", false, { win = 0 })
		vim.api.nvim_set_option_value("relativenumber", false, { win = 0 })

		local title = vim.split(M.title, "\n")
		M.InsertToBuf(M.title_margin, title, buf, 0)

		local art = require("startup.art"):GetRandArt()
		M.InsertToBuf(art.margin, art.text, buf, 7)

		vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
		vim.api.nvim_set_current_buf(buf)
	end
end

return M
