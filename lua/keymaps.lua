vim.g.mapleader = " "

vim.keymap.set("n", "<Leader>c", "", { desc = "Config" })
vim.keymap.set("n", "<Leader>rr", function()
	vim.cmd.Reload()
end, { desc = "Reload" })

-- Buffers
vim.keymap.set("n", "<Leader>b", "", { desc = "Buffer" })
vim.keymap.set("n", "<Leader>bd", function()
	vim.cmd.tabclose()
end, { desc = "Close Buffer" })

vim.keymap.set("n", "<Leader>bo", function()
	vim.cmd.tabonly()
end, { desc = "Close Other Buffers" })

vim.keymap.set("n", "<Leader>br", function()
	vim.cmd("+1,$tabdo :q")
end, {})

vim.keymap.set("n", "<Leader>bl", function()
	vim.cmd("0,-1tabdo :q")
end, {})

vim.keymap.set("n", "<s-H>", function()
	vim.cmd("tabprev")
end, { desc = "Reload" })

vim.keymap.set("n", "<s-L>", function()
	vim.cmd("tabnext")
end, { desc = "Reload" })

-- LSP
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Find References" })
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Find Definitions" })
vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Find Implementations" })

vim.keymap.set("n", "<leader>sS", function()
	vim.lsp.buf.workspace_symbol()
end, { desc = "List workspace symbols" })

vim.keymap.set("n", "<leader>ss", function()
	vim.lsp.buf.document_symbol()
end, { desc = "List buffer symbols" })

vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename Symbol" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })

vim.keymap.set("n", "[w", function()
	vim.diagnostic.goto_prev({ severity = 2 })
end, { desc = "Prev Error" })

vim.keymap.set("n", "]w", function()
	vim.diagnostic.goto_next({ severity = 2 })
end, { desc = "Next Error" })

vim.keymap.set("n", "[e", function()
	vim.diagnostic.goto_prev({ severity = 1 })
end, { desc = "Prev Error" })

vim.keymap.set("n", "]e", function()
	vim.diagnostic.goto_next({ severity = 1 })
end, { desc = "Next Error" })

-- Window switching
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- Convenience for completing various common characters that come in pairs
local function skip_pair(pair)
	return function()
		local line = vim.api.nvim_get_current_line()
		local col = vim.api.nvim_win_get_cursor(0)[2]

		if line:sub(col + 1, col + 1) == pair then
			return "<Right>"
		end

		return pair
	end
end

vim.keymap.set("i", '"', skip_pair('"'), { expr = true })
vim.keymap.set("i", "'", skip_pair("'"), { expr = true })
vim.keymap.set("i", ")", skip_pair(")"), { expr = true })
vim.keymap.set("i", "}", skip_pair("}"), { expr = true })
vim.keymap.set("i", "]", skip_pair("]"), { expr = true })

vim.keymap.set("i", "(", "()<left>", { nowait = true })
vim.keymap.set("i", "[", "[]<left>", { nowait = true })
vim.keymap.set("i", "{", "{}<left>", { nowait = true })
