M = {}

M.filetype = { "h", "cpp", "c" }
M.file_ext = { "*.h", "*.cpp", "*.c" }
M.config = {
	name = "clangd",
	cmd = { "clangd" },
	root_dir = vim.fs.dirname(vim.fs.find({ "compile_commands.json" }, { upward = true })[1]),
}

return M
