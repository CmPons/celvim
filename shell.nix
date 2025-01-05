{pkgs ? import <nixpkgs> {}}: let
  # Create a bare-bones Neovim package without any extra configuration
in
  pkgs.mkShell {
    # Include only the clean Neovim and any essential build tools you might need
    packages = [
      pkgs.neovim
      # Add any development tools you need, like:
      pkgs.gcc # If you need a C compiler
    ];

    # Set up environment variables to ensure clean paths
    shellHook = ''
      # Set NVIM_APPNAME to your development config
      export NVIM_APPNAME=celvim

      echo "Entering clean Neovim development environment"
      echo "NVIM_APPNAME is set to: $NVIM_APPNAME"
    '';
  }
