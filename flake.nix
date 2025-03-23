{
  description = "A flake setting up CelVim";
  inputs = { flake-utils.url = "github:numtide/flake-utils"; };
  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      celvim = pkgs.writeShellScriptBin "cvim" ''nvim'';
      in {

        devShells.default = pkgs.mkShell {
          NVIM_APPNAME = "celvim";

          packages = with pkgs; [
            neovim
            celvim

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

          shellHook = ''
            ln -sfn ${self.outPath} ~/.config/$NVIM_APPNAME
          '';
        };
      });
}
