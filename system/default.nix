{ pkgs, ... }:

{
  imports = [
    ./git
    ./gnome
    ./network-sharing
    ./fonts
    ./zsh
    ./nautilus
    ./thumbnails
    ./docker
    ./nix-gaming
  ];
}
