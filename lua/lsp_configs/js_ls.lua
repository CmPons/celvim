M = {}

M.filetype = "javascript"
M.file_ext = "*.js"
M.config = {
	name = "ts-ls",
	cmd = { "typescript-language-server", "--stdio" },
	root_dir = vim.fs.dirname(
		vim.fs.find({ "package.json", "tsconfig.json", "jsconfig.json", ".git" }, { upward = true })[1]
	),
}

return M
