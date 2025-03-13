M = {}
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

M.filetype = "rs"
M.file_ext = "*.rs"
M.config = {
	name = "rust-lsp",
	cmd = { "rust-analyzer" },
	root_dir = vim.fs.dirname(vim.fs.find({ "Cargo.lock" }, { upward = true })[1]),
	capabilities = capabilities,
	init_options = {
		completion = {
			postfix = {
				enable = true,
			},
		},
	},
}

return M
