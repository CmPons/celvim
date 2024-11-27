vim.g.mapleader = " "

vim.keymap.set("n", "<Leader>c", "", { desc = "Config" })
vim.keymap.set("n", "<Leader>cr", function()
	vim.cmd("Reload")
end, { desc = "Reload" })

vim.keymap.set("n", "<s-H>", function()
	vim.cmd("tabprev")
end, { desc = "Reload" })

vim.keymap.set("n", "<s-L>", function()
	vim.cmd("tabnext")
end, { desc = "Reload" })
