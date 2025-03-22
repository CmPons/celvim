{
  description = "A flake setting up CelVim";
  inputs = { flake-utils.url = "github:numtide/flake-utils"; };
  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            neovim

            # Utils
            tree
            fzf

            # LSPs and Formatters
            cargo
            clang-tools
            lua-language-server
            nixfmt
            nixd
            omnisharp-roslyn
            stylua
            shfmt
          ];
          NVIM_APPNAME = "celvim";
          XDG_CONFIG_HOME = ".";
        };
      });
}
