vim.g.netrw_banner = false
-- Makes sure hidden files (those starting with .)
-- are hidden by default
-- SEE: help netrw-edithide
vim.g.netrw_list_hide = [[\(^\|\s\s\)\zs\.\S\+]]
-- Tree style listing
vim.g.netrw_liststyle = 3

vim.keymap.set("n", "<Leader>f", "", { desc = "Files" })
vim.keymap.set("n", "<Leader>fe", function()
	vim.cmd("edit .")
end, {})
