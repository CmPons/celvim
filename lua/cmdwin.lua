-- Hide the cmd line
vim.o.cmdheight = 0

-- Setup the cmdwindow in place of the cmdline
-- Then we can make it floating and pretty it up!
vim.keymap.set("n", ":", "q:", {})

vim.api.nvim_create_autocmd("CmdwinEnter", {
	callback = function()
		-- Force insert mode
		vim.cmd.startinsert()

		local config = {
			relative = "editor",
			row = 10,
			col = 25,
			width = 100,
			height = 1,
			border = "double",
			style = "minimal",
			title = "Cmd",
		}

		vim.api.nvim_win_set_config(0, config)
		vim.keymap.set("n", "<esc>", ":q<enter>", { buffer = 0 })
	end,
})
