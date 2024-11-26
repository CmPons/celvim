vim.g.mapleader = " "

vim.keymap.set("n", "<Leader>c", "", { desc = " Config" })

vim.keymap.set("n", "<Leader>cr", function()
	vim.cmd("Reload")
end, { desc = "Reload" })
