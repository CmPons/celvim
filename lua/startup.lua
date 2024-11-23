vim.cmd("colorscheme nord")

math.randomseed(os.time())

local art = require("art")
local idx = math.random(1, #art)
local selected_art = art[idx]
local replacement = vim.split(selected_art, "\n")

local buf = vim.api.nvim_create_buf(true, true)
vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, replacement)
vim.api.nvim_set_current_buf(buf)

local win = vim.api.nvim_open_win(buf, true, { relative = "editor", row = 0, col = 0, width = 100, height = 400 })
vim.api.nvim_win_set_buf(win, buf)
