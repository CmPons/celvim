M = {}
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.experimental = {
	hoverActions = true,
	colorDiagnosticOutput = true,
	hoverRange = true,
	serverStatusNotification = true,
	snippetTextEdit = true,
	codeActionGroup = true,
	ssr = true,
	localDocs = true,
}
capabilities.textDocument.completion.completionItem.resolveSupport = {
	properties = { "documentation", "detail", "additionalTextEdits" },
}

M.filetype = "rust"
M.file_ext = "*.rs"
M.config = {
	name = "rust-lsp",
	cmd = { "rust-analyzer" },
	root_dir = vim.fs.dirname(vim.fs.find({ "Cargo.lock" }, { upward = true })[1]),
	capabilities = capabilities,
	settings = {
		["rust-analyzer"] = {
			check = {
				command = "clippy",
				extraArgs = "--workspace --tests",
			},
		},
	},
	init_options = {
		completion = {
			postfix = {
				enable = true,
			},
		},
	},
}

return M
