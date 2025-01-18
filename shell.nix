{ pkgs ? import (fetchTarball
  "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") { } }:
let
in pkgs.mkShell {
  packages = with pkgs; [ neovim nixfmt stylua ];

  shellHook = ''
    # Set NVIM_APPNAME to your development config
    export NVIM_APPNAME=celvim

    echo "Entering clean Neovim development environment"
    echo "NVIM_APPNAME is set to: $NVIM_APPNAME"
  '';
}
