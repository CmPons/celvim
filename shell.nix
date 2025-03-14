{ pkgs ? import (fetchTarball
  "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") { }, }:
let
in pkgs.mkShell {
  packages = with pkgs; [ neovim nixfmt stylua shfmt omnisharp-roslyn ];

  shellHook = ''
    export NVIM_APPNAME=celvim
  '';
}
