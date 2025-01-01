-- No help banner at top
vim.g.netrw_banner = false
-- Hide hidden files
vim.g.netrw_list_hide = [[\(^\|\s\s\)\zs\.\S\+]]
-- Tree style listing
vim.g.netrw_liststyle = 3

vim.keymap.set("n", "<Leader>f", "", { desc = "Files" })
vim.keymap.set("n", "<Leader>fe", function()
	vim.cmd.tabnew()
	vim.cmd.Explore()

	vim.keymap.set("n", "<esc>", ":q<enter>", { buffer = 0 })
end, { desc = "File Explorer" })
