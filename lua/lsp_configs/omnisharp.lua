M = {}

M.filetype = "cs"
M.file_ext = "*.cs"
M.config = {
	name = "omnisharp",
	cmd = {
		"OmniSharp",
		"-z",
		"--hostPID",
		tostring(vim.fn.getpid()),
		"DotNet:enablePackageRestore=false",
		"--encoding",
		"utf-8",
		"--languageserver",
	},
	root_dir = vim.fs.dirname(
		vim.fs.find({ "*.sln", "*.csproj", "omnisharp.json", "function.json" }, { upward = true })[1]
	),
}

return M
