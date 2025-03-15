{ pkgs ? import (fetchTarball
  "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") { }, }:
let
in pkgs.mkShell {
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

  shellHook = ''
    export NVIM_APPNAME=celvim
  '';
}
