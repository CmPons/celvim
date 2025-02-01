local M = {}

M.keymaps = {}

M.set_keymap = function(mode, lhs, rhs, opts)
	M.keymaps[#M.keymaps + 1] = { mode = mode, lhs = lhs }
	vim.keymap.set(mode, lhs, rhs, opts)
end

M.Init = function()
	vim.g.mapleader = " "

	M.set_keymap("n", "<Leader>rr", function()
		vim.cmd.Reload()
	end, { desc = "Reload" })

	-- Buffers
	M.set_keymap("n", "<Leader>bd", function()
		vim.cmd.tabclose()
	end, { desc = "Close Buffer" })

	M.set_keymap("n", "<Leader>bo", function()
		vim.cmd.tabonly()
	end, { desc = "Close Other Buffers" })

	M.set_keymap("n", "<Leader>br", function()
		vim.cmd("+1,$tabdo :q")
	end, {})

	M.set_keymap("n", "<Leader>bl", function()
		vim.cmd("0,-1tabdo :q")
	end, {})

	M.set_keymap("n", "<s-H>", function()
		vim.cmd("tabprev")
	end, { desc = "Reload" })

	M.set_keymap("n", "<s-L>", function()
		vim.cmd("tabnext")
	end, { desc = "Reload" })

	-- LSP
	M.set_keymap("n", "gr", vim.lsp.buf.references, { desc = "Find References" })
	M.set_keymap("n", "gd", vim.lsp.buf.definition, { desc = "Find Definitions" })
	M.set_keymap("n", "gi", vim.lsp.buf.implementation, { desc = "Find Implementations" })

	M.set_keymap("n", "<leader>sS", function()
		vim.lsp.buf.workspace_symbol()
	end, { desc = "List workspace symbols" })

	M.set_keymap("n", "<leader>ss", function()
		vim.lsp.buf.document_symbol()
	end, { desc = "List buffer symbols" })

	M.set_keymap("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename Symbol" })
	M.set_keymap("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })

	M.set_keymap("n", "[w", function()
		vim.diagnostic.goto_prev({ severity = 2 })
	end, { desc = "Prev Error" })

	M.set_keymap("n", "]w", function()
		vim.diagnostic.goto_next({ severity = 2 })
	end, { desc = "Next Error" })

	M.set_keymap("n", "[e", function()
		vim.diagnostic.goto_prev({ severity = 1 })
	end, { desc = "Prev Error" })

	M.set_keymap("n", "]e", function()
		vim.diagnostic.goto_next({ severity = 1 })
	end, { desc = "Next Error" })

	-- Window switching
	M.set_keymap("n", "<C-j>", "<C-w>j")
	M.set_keymap("n", "<C-k>", "<C-w>k")
	M.set_keymap("n", "<C-h>", "<C-w>h")
	M.set_keymap("n", "<C-l>", "<C-w>l")

	M.set_keymap("i", "(", "()<left>", { nowait = true })
	M.set_keymap("i", "[", "[]<left>", { nowait = true })
	M.set_keymap("i", "{", "{}<left>", { nowait = true })
end

M.Cleanup = function()
	for _, keymap in ipairs(M.keymaps) do
		vim.keymap.del(keymap.mode, keymap.lhs)
	end
end

return M
