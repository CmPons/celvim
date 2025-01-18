M = {}

M.filetype = "nix"
M.file_ext = "*.nix"
M.config = {
	name = "nixd",
	cmd = { "nixd" },
	root_dir = vim.fs.dirname(vim.fs.find({ ".git" }, { upward = true })[1]),

	settings = {
		nixd = {
			nixpkgs = {
				expr = "import <nixpkgs> { }",
			},
			formatting = {
				command = "nixfmt",
			},
			options = {
				nixos = {
					expr = '(builtins.getFlake "/etc/nixos").nixosConfigurations.desktop.options',
				},
				home_manager = {
					expr = '(builtins.getFlake "/etc/nixos").homeConfigurations.desktop.options',
				},
			},
		},
	},
}

return M
