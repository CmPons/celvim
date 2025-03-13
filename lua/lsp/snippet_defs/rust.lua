M = {}
M.filetype = "rust"
M.snippets = {
	{
		kind = "Snippet",
		word = "fn",
		abbr = "fn",
		user_data = {
			nvim = {
				lsp = {
					completion_item = {
						insertText = "fn $1($2) {\n\t$0\n}",
					},
				},
			},
		},
	},
	{
		kind = "Snippet",
		word = "fnr",
		abbr = "fnr",
		user_data = {
			nvim = {
				lsp = {
					completion_item = {
						insertText = "fn $1($2) -> Result<$3> {\n\t$0\n}",
					},
				},
			},
		},
	},
	{
		kind = "Snippet",
		word = "tfn",
		abbr = "tfn",
		user_data = {
			nvim = {
				lsp = {
					completion_item = {
						insertText = "#[test]\nfn $1($2) {\n\t$0\n}",
					},
				},
			},
		},
	},
	{
		kind = "Snippet",
		word = "tfnr",
		abbr = "tfnr",
		user_data = {
			nvim = {
				lsp = {
					completion_item = {
						insertText = "#[test]\nfn $1($2) -> Result<$3> {\n\t$0\n}",
					},
				},
			},
		},
	},
	{
		kind = "Snippet",
		word = "tmod",
		abbr = "tmod",
		user_data = {
			nvim = {
				lsp = {
					completion_item = {
						insertText = "#[cfg(test)]\nmod test {\n\t$0\n}",
					},
				},
			},
		},
	},
}

return M
