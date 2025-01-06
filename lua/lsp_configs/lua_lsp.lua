M = {}

M.filetype = "lua"
M.file_ext = "*.lua"
M.config = {
	name = "lua-lsp-server",
	cmd = { "lua-language-server" },
	root_dir = vim.fs.dirname(vim.fs.find({ ".git" }, { upward = true })[1]),

	-- Note Lua must be capital. This setting is to remove complaints about unknown global "vim"
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
			runtime = {
				version = "LuaJIT",
			},
			workspace = {
				-- This lets the lsp know where the Neovim lua runtime files are
				-- and enables auto-complete with the Neovim api.
				library = vim.api.nvim_get_runtime_file("", true),
			},
		},
	},
}

return M
