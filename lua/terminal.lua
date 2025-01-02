vim.keymap.set("n", "<C-/>", function()
	vim.cmd("Terminal")
end, {})

vim.cmd([[tnoremap <Esc> <C-\><C-n>]])

vim.api.nvim_create_user_command("Terminal", function()
	vim.cmd("tabnew")
	vim.cmd(":term")
	vim.cmd("startinsert")
	vim.keymap.set("n", "<esc>", ":q<enter>", { buffer = vim.api.nvim_get_current_buf() })
end, {})
