-- No help banner at top
vim.g.netrw_banner = false
-- Hide hidden files
vim.g.netrw_list_hide = [[\(^\|\s\s\)\zs\.\S\+]]
-- Tree style listing
vim.g.netrw_liststyle = 3
-- 20% of screen
vim.g.netrw_winsize = 20
-- Open file in new tab
vim.g.netrw_browse_split = 3

vim.keymap.set("n", "<Leader>f", "", { desc = "Files" })
vim.keymap.set("n", "<Leader>fe", function()
	vim.cmd.Vexplore()

	vim.keymap.set("n", "<esc>", ":q<enter>", { buffer = 0 })

	-- All of this is here to close the netrw pane when we select a file
	local netrw_buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_create_autocmd({ "BufLeave" }, {
		callback = function()
			vim.schedule(function()
				vim.api.nvim_buf_delete(netrw_buf, {})
			end)
		end,
		buffer = netrw_buf,
	})
end, { desc = "File Explorer" })
