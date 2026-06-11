{ pkgs, inputs, ... }:

{
  imports = [
    ./wm
    ./thumbnails
    ./torrent
    ./git.nix
    ./zsh.nix
    ./direnv.nix
    ./fonts.nix
    ./firefox.nix
    ./nautilus.nix
    ./docker.nix
    ./network-sharing.nix
  ];
}
