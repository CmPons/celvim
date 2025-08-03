M = {}
M.filetype = "rust"
M.snippets = {
	{
		kind = "Snippet",
		word = "fnr",
		abbr = "fnr",
		user_data = {
			nvim = {
				lsp = {
					completion_item = {
						textEdit = {
							newText = "fn $1($2) -> Result<$3> {\n\t$0\n}",
						},
						insertTextFormat = 2,
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
						textEdit = {
							newText = "#[test]\nfn $1($2) {\n\t$0\n}",
						},
						insertTextFormat = 2,
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
						textEdit = {
							newText = "#[test]\nfn $1($2) -> Result<$3> {\n\t$0\n}",
						},
						insertTextFormat = 2,
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
						textEdit = {
							newText = "#[cfg(test)]\nmod test {\n\t$0\n}",
						},
						insertTextFormat = 2,
					},
				},
			},
		},
	},
}

return M
