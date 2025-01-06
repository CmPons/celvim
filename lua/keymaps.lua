vim.g.mapleader = " "

vim.keymap.set("n", "<Leader>c", "", { desc = "Config" })
vim.keymap.set("n", "<Leader>cr", function()
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

vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })

-- Window switching
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-l>", "<C-w>l")
