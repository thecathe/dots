{ pkgs, inputs, ... }:

{
  imports = [
    ./wm
    ./thumbnails
    ./git.nix
    ./neovim.nix
    ./zsh.nix
    ./direnv.nix
    ./fonts.nix
    ./firefox.nix
    ./nautilus.nix
    ./docker.nix
    ./network-sharing.nix
    ./nix-gaming.nix
  ];
}
