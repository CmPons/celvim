vim.cmd("colorscheme nord")

math.randomseed(os.time())

local f = [[

╔════════════════════════════════════════╗
║  ___  ____  __          _  _  __  _  _ ║
║ / __)(  __)(  )        / )( \(  )( \/ )║
║( (__  ) _) / (_/\      \ \/ / )( / \/ \║
║ \___)(____)\____/       \__/ (__)\_)(_/║
╚════════════════════════════════════════╝

]]

local window_size = { width = vim.o.columns, height = vim.o.lines }

local art = require("art")
local idx = math.random(1, #art)
local selected_art = art[idx]

local title = vim.split(f, "\n")
local art = vim.split(selected_art, "\n")

local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})
vim.api.nvim_buf_set_lines(buf, 0, -1, false, title)
vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
vim.api.nvim_set_current_buf(buf)

local win = vim.api.nvim_open_win(
	buf,
	true,
	{ relative = "editor", row = 0, col = 0, width = window_size.width, height = window_size.height }
)
vim.api.nvim_win_set_buf(win, buf)
