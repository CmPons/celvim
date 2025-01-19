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
        command = { "nixfmt" },
      },
      options = {
        nixos = {
          expr = '(builtins.getFlake "/etc/nixos").nixosConfigurations.desktop.options',
        },
        -- Does not seem to work since I use home-manager as a Nixos module!
        -- home_manager = {
        -- 	expr = '(builtins.getFlake "/etc/nixos").homeConfigurations.desktop.options',
        -- },
      },
    },
  },
}

return M
